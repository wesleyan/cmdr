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
	# strings to and from the device. However, most devices should be able to take advantage
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
	# 
	# These abstractions are designed around devices that have the following message lifecycle:
	# 
	# 1. A message is sent from the controller to the device
	# 2. The device processes the event and sends back a response, either an acknowledge or a full response.
	# 3. The device is now ready for a new message, starting the cycle over.
	# 
	# In particular, since many devices can only handle one message at a time, RS232Device waits
	# until a response is received or {RS232Device::TIMEOUT TIMEOUT} seconds have passed before
	# sending the next message in the queue. Devices with more complex message handling (for example,
	# those with multiple message queues) may not work optimally with this strategy. In those cases,
	# writing the message handling system yourself may be preferable. 
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
		
		# Creates a new RS232Device instance
		# @param [String, Symbol] name The name of the device, which is stored in the database
		# 	and used to communicate with it over AMQP
		# @param [Hash{String, Symbol => Object}] hash A hash of configuration definitions, from
		# 	the name of the config var to its value
		# @param [String] db_uri The URI of the CouchDB database where updates should be saved
		# @param [String] dqueue The AMQP queue that the device watches for messages
		def initialize(name, options, db_uri = "http://localhost:5984/rooms", dqueue = nil)
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
			super(name, options, db_uri, dqueue)
		end

		# Sends a string to the serial device
		# @param [String] string The string to send
		def send_string(string)
			@serialport.send_data(string) if @serialport
		end
		
		# Run is a blocking call that starts the device. While run is running, the device will
		# watch for AMQP events as well as whatever communication channels the device uses and
		# react appropriately to events. It will also send requests if any have been specified.
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
		
		# This method, when called in a class body, creates a managed state var. A managed state
		# var is very much like a normal {Device::state_var state_var}, but expects that a proc
		# be supplied to action which returns the string to send to the device. It then creates 
		# the set_* method automatically and handles all device communication for you.
		# @param [Symbol] name The name for the managed state var. Should follow the general
		# 	naming conventions: all lowercase, with multiple words connected\_by\_underscores.
		# @param [Hash] options Options for configuring the managed\_state\_var
		# @option options [Symbol] :type [mandatory] the type of the variable; this is
		# 	used by the web interface to decide what kind of interface to show. Possible
		# 	values are :boolean, :string, :percentage, :number, :decimal, :option, and
		# 	:array.
		# @option options [Boolean] :editable (true) whether or not this variable can be set
		# 	by the user.
		# @option options [Integer] :display_order Used by the web interface to decide which
		# 	variables are visible and in which order they are displayed. For a particular
		# 	device, the var with the lowest :display_order is ranked highest, followed by
		# 	the next lowest up to 6. Leave out if the variable should not be shown.
		# @option options [Array<#to_json>] :options If :option is selected for type, the
		# 	elements in this array serve as the allowable options.
		# @option options [Proc] :action [mandatory] If a proc is supplied to :action, then
		# 	managed\_state\_varwill automatically create a set_varname method (where varname
		# 	is the name of the state variable) which executes the code provided. This proc 
		# 	should return the string which, when sent to the device, will cause it to enter
		# 	the chosen state.
		# @example
		# 	maanged_state_var :input, 
		# 		:type => :option, 
		# 		:display_order => 1, 
		# 		:options => ("1".."6").to_a,
		# 		:action => proc{|input|
		# 			"{input}!\r\n"
		# 		}
		def self.managed_state_var name, options
			throw "Must supply a proc to :action" unless options[:action].is_a? Proc
			state_var name, options
			define_method "set_#{name}".to_sym, proc {|value|
				message = options[:action].call(value)
				deferrable = EM::DefaultDeferrable.new
				do_message message, deferrable
				deferrable
			}				
		end
		
		# @private
		# Adds a message to the back of the send queue, creating it if it does not exist
		# @param [String] message The message to add
		# @param [EM::Deferrable] deferrable The deferrable associated with the message
		def do_message(message, deferrable = nil)
			@_send_queue ||= []
			@_send_queue.unshift [message, deferrable]
		end
		
		# @private
		# A simple class which is used for parsing responses by means of instance_eval
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
		
		# Starts a responses block, wherein statements which describe the various kinds of
		# responses the device can send are placed. There are four kinds of responses:
		# 
		# + *match*, which is used for general responses
		# + *ack*, which is used for acknowledge responses, sent by devices to announce
		# 	that the message has been received and the next can be sent
		# + *nack*, not acknowledged, meaning that the message was received but could not
		# 	be interpretted or executed
		# + *error*, meaning that there was some error running the previous message
		# 
		# Match is used most frequently, whereas the others are applicable only to some devices
		# which have those features. Each response takes a matcher, which can either be a string,
		# regular expression or a proc. Whenever a message is received, it is compared to each
		# of the matchers that have been defined in order, and the first matcher to match (defined
		# as being equal for strings, returning a non-nil value from `String#match` for regular
		# expression, or returning a true value when supplied the message for procs) is used.
		# When a response created with `match` is selected, the supplied "interpreter" proc is called,
		# which will generally update state vars. The argument to the interpreter depends on the
		# matcher type. For strings, no argument is supplied; for regular expressions, the matcher
		# object is supplied; for procs, the original message is supplied. When an `error` response is 
		# matched, the supplied message is returned to the user. When either an `ack` or `nack` response 
		# is matched, the next message is sent and no futher action taken.
		# 
		# `match` takes three arguments: a name, a matcher and an interpreter. `nack` and `ack` each
		# take only a matcher. `error` takes a name, a matcher and a string message.
		# @example
		# 	responses do
		# 		#regular expression matcher
		# 		match :volume, /Vol(\d+)/, proc{|m| self.volume = m[1].to_i/100.0}
		# 		#string matcher
		# 		match :powered_on, "power=on", proc{ self.power = true}
		# 		#proc matcher
		# 		match :input, proc{|m| m[0] == 2 && m[1] == 0x15}, proc{|m| self.input = m[4].to_i * 2**8 + m[5].to_i}
		# 		ack "ack"
		# 		nack "nack"
		# 		error :power_error, "power_error", "Projector failed to turn on"
		# 	end
		def self.responses &block
			rh = ResponseHandler.new
			rh.instance_eval(&block)
			@_matchers ||= []
			@_matchers += rh.matchers if rh.matchers
		end
		
		def matchers
			self.class.instance_variable_get(:@_matchers)
		end
		
		# @private
		# A simple class which is used for parsing requests by means of instance_eval
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
