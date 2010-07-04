require 'strscan'
module Wescontrol
	class ManagedRS232Device < RS232Device
		TIMEOUT = 0.5 #number of seconds to wait for a reply
		configure do
			message_end "\r\n"
		end
		
		def initialize name, options
			@_send_queue = []
			@_ready_to_send = true
			super(name, options)
		end
		
		def run
			EM::run {
				ready_to_send = true
				EM::add_periodic_timer(TIMEOUT) { self.ready_to_send = @_ready_to_send}
				super
			}
		end
				
		def self.state_var name, options
			#throw "Must have :action field of type Proc" unless options[:action].class == Proc
			#throw "Must have :response field" unless options[:response]
			super name, options
			
			if options[:action].is_a? Proc
				define_method "set_#{name}".to_sym, proc {|value|
					message = options[:action].call(value)
					deferrable = EM::DefaultDeferrable.new
					do_message message, deferrable
					deferrable
				}
			end
		end
		
		def do_message(message, deferrable = nil)
			@_send_queue ||= []
			@_send_queue.unshift [message, deferrable]
		end
		
		class ResponseHandler
			attr_reader :matchers
			def initialize
				@matchers = []
			end
			def match name, matcher, interpreter
				@matchers << [name, matcher, interpreter]
			end
			def ack matcher
				@matchers << [:ack, matcher]
			end
			def nack matcher
				@matchers << [:nack, matcher]
			end
			def error name, matcher, message = nil
				@matchers << [:error, matcher, message]
			end
		end
		
		def self.responses &block
			rh = ResponseHandler.new
			rh.instance_eval(&block)
			@_matchers ||= []
			@_matchers += rh.matchers if rh.matchers
		end
		
		def matchers
			self.class.instance_variable_get(:@_matchers)
		end
		
		class RequestHandler
			attr_reader :requests
			def send name, req, freq
				@requests ||= []
				@requests << [name, req, freq]
			end
		end
		
		def self.requests &block
			rh = RequestHandler.new
			rh.instance_eval(&block)
			@_requests ||= []
			@_requests += rh.requests
			@_request_scheduler = []
			multiplier = 1.0/@_requests.collect{|x| x[2]}.min
			r = @_requests.collect{|x| [x[0], x[1], (x[2]*multiplier).to_i]}
			iter = 0
			r.inject(0){|sum, x|x[2] + sum}.times{|i|
				while r[iter % r.size][2] == 0
					iter += 1
				end
				r[iter % r.size][2] -= 1
				@_request_scheduler << r[iter % r.size]
			}
		end
		
		def request_scheduler
			self.class.instance_variable_get(:@_request_scheduler)
		end
		
		def read data
			@_buffer ||= ""
			@_responses ||= {}
			@_buffer << data
			s = StringScanner.new(@_buffer)
			while msg = s.scan(/.+?#{configuration[:message_end]}/) do
				msg.gsub!(configuration[:message_end], "")
				m = matchers.find{|matcher|
					result = case matcher[1].class.to_s
						when "Regexp" then msg.match(matcher[1])
						when "Proc" then matcher[1].call(msg)
						when "String" then matcher[1] == msg
					end
				} if matchers
				if m
					if @_message_handler
						case m[0]
							when :ack then
								@_message_handler.succeed
							when :nack then
								@_message_handler.fail
							when :error then
								resp = m[2].is_a? Proc ? m[2].call(msg) : m[2]
								@_message_handler.fail resp
							else
								@_message_handler.succeed instance_exec(msg, &m[2])
						end
						@_message_handler = nil
					else
						instance_exec(msg, &m[2])
					end
				end
			end
			@_buffer = s.rest
			#if we got the message end signal, we're safe to send the next thing
			if data.match(configuration[:message_end])
				self.ready_to_send = true
			end
		end
		
		def ready_to_send=(state)
			@_ready_to_send = state
			@_ready_to_send = true if !@_last_sent_time || Time.now - @_last_sent_time > TIMEOUT

			if @_ready_to_send
				if @_send_queue.size == 0
					request = choose_request
					do_message request if request
				end
				send_from_queue
			end
		end

		def ready_to_send; @_ready_to_send; end
		
		def send_from_queue
			if message = @_send_queue.pop
				@_last_sent_time = Time.now
				@_ready_to_send = false
				@_message_handler = message[1] ? message[1] : EM::DefaultDeferrable.new
				@_message_handler.timeout(TIMEOUT)
				send_string message[0]
			end
		end
		
		def choose_request
			return nil unless request_scheduler
			@_request_iter ||= -1
			@_request_iter += 1
			request_scheduler[@_request_iter % request_scheduler.size][1]
		end
	end
end