require 'rubygems'
require 'strscan'
require "#{File.dirname(__FILE__)}/em-serialport"
require 'bit-struct'

module Wescontrol
	# RS232Device is a subclass of {Wescontrol::Device} that makes the job of controlling
	# devices that communicate over RS232 serial ports easier. At its most basic level, it
	# will handle communication through a serial port (using the
	# [ruby-serialport](http://ruby-serialport.rubyforge.org/) library) for you, providing
	# {#send_string} and {#read}, which respectively send and receive 
	# strings to and from the device. However, most devices should be able to take advatange
	# of the various "managed" features, which can greatly simplify the task of writing drivers
	# for RS232 devices. In fact, using this class it is possible to write drivers without any
	# real code at all besides some string handling.
	# 
	# There are several abstractions provided which can take over a part of device handling.
	# Perhaps the most widely applicable is the {RS232Device::requests requests} abstraction.
	# Many devices will not send messages to notify a state change and must be constantly
	# polled to maintain correct state in the Roomtrol system (i.e., if a projector is turned
	# off manually, you must request its power state in order to display that fact on the
	# touchscreen). You can use `request` to do such polling automatically. You can provide
	# as many requests as you'd like, and each can have an associated priority which informs
	# how often is should be sent. Look at the {RS232Device::requests} documentation for more
	# information.
	# 
	# The next abstraction is {RS232Device::responses responses}. Responses provide automatic
	# handling of incoming data from the device. Each response has a "matcher," which can be
	# a string, regular expression or a function. When a message comes over the wire from the
	# device, it is matched against all of the responses. If one matches, the message is passed
	# to the handler function provided, which will generally update one or more state_vars based
	# on the information provided.
	# 
	# The final abstraction is {RS232Device::managed_state_var}. A managed state var is like a 
	# normal {Device::state_var} except that the set_ method is created automatically based on
	# a string function provided to :action.
	# 
	# Using these three abstractions, you can write device drivers using very little code. For
	# example, here's a subset of the ExtronVideoSwitcher driver (the full source can be found
	# [here](https://github.com/mwylde/roomtrol-devices/blob/master/ExtronVideoSwitcher.rb)).
	# 
	# 	configure do
	# 		baud        9600
	# 		message_end "\r\n"
	# 	end
	# 
	# 	managed_state_var :input, 
	# 		:type => :option, 
	# 		:display_order => 1, 
	# 		:options => ("1".."6").to_a,
	# 		:response => :channel,
	# 		:action => proc{|input|
	# 			"#{input}!\r\n"
	# 		}
	# 
	# 	responses do
	# 		match :channel,  /Chn\d/, proc{|r| self.input = r.strip[-1].to_i.to_s}
	# 		match :volume,   /Vol\d+/, proc{|r| self.volume = r.strip[3..-1].to_i/100.0}
	# 		match :mute,     /Amt\d+/, proc{|r| self.mute = r[-1] == "1"}
	# 		match :status,   /Vid\d+ Aud\d+ Clp\d/, proc{|r|
	# 			input = r.scan(/Vid\d+/).join("")[3..-1].to_i
	# 			self.input = input if input > 0
	# 			self.clipping = r.scan(/Clp\d+/).join("")[3..-1] == "1"
	# 		}
	# 	end
	# 
	# 	requests do
	# 		send :input, "I\r\n", 0.5
	# 		send :volume, "V\r\n", 0.5
	# 		send :mute, "Z\r\n", 0.5
	# 	end
	class RS232Device < Device
		# The number of seconds to way for a reply before transmitting the next message
		TIMEOUT = 0.5
		# The SerialPort object over which data is sent and received from the device
		attr_accessor :serialport

		configure do
			port :type => :port
			baud :type => :integer, :default => 9600
			data_bits 8
			stop_bits 1
			parity 0
			message_end "\r\n"
		end

		def send_string(string)
			@serialport.send_data(string) if @serialport
		end
		
		def run
			EM::run {
				begin
					ready_to_send = true
					EM::add_periodic_timer(TIMEOUT) { self.ready_to_send = @_ready_to_send}
					EM::open_serial @port, @baud, @data_bits, @stop_bits, @parity, @connection
				rescue
					DaemonKit.logger.error "Failed to open serial: #{$!}"
				end
				super
			}
			
		end
	
		def initialize(name, options)
			options = options.symbolize_keys
			@port = options[:port]
			throw "Must supply serial port parameter" unless @port
			@baud = options[:baud] ? options[:baud] : 9600
			@data_bits = options[:data_bits] ? options[:data_bits] : 8
			@stop_bits = options[:stop_bits] ? options[:stop_bits] : 1
			@parity = options[:parity] ? options[:parity] : 0
			@connection = RS232Connection.dup
			@connection.instance_variable_set(:@receiver, self)
			
			@_send_queue = []
			@_ready_to_send = true
			super(name, options)
		end
		
		def self.managed_state_var name, options
			state_var name, options
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
					case matcher[1].class.to_s
						when "Regexp" then msg.match(matcher[1])
						when "Proc" then matcher[1].call(msg)
						when "String" then matcher[1] == msg
					end
				} if matchers
				if m
					arg = msg
					arg = msg.match(m[1]) if m[1].is_a? Regexp
					if @_message_handler
						case m[0]
							when :ack then
								@_message_handler.succeed
							when :nack then
								@_message_handler.fail
							when :error then
								resp = m[2].is_a? Proc ? m[2].call(arg) : m[2]
								@_message_handler.fail resp
							else
								@_message_handler.succeed instance_exec(arg, &m[2])
						end
						@_message_handler = nil
					else
						instance_exec(arg, &m[2])
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

class RS232Connection < EM::Connection
	def initialize
		@receiver ||= self.class.instance_variable_get(:@receiver)
		@receiver.serialport = self
	end
	def receive_data data
		@receiver.read data if @receiver
	end	
end
