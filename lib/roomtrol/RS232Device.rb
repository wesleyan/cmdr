require 'rubygems'
require 'strscan'
require 'roomtrol/em-serialport'
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
	# real code at all (besides some string handling).
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
	# 		match :channel,  /Chn(\d)/, proc{|m| self.input = m[1].to_i.to_s}
	# 		match :volume,   /Vol(\d+)/, proc{|m| self.volume = m[1].to_i/100.0}
	# 		match :mute,     /Amt(\d+)/, proc{|m| self.mute = m[1] == "1"}
	# 		match :status,   /Vid(\d+) Aud(\d+) Clp(\d)/, proc{|m|
	# 			self.input = m[1].to_i if m[1].to_i > 0
	# 			self.clipping = (m[2] == "1")
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
	# writing the message handling system yourself may be preferable. It is also very important that
	# devices are synchronous; i.e., they always send responses in the order that requests or commands
	# are received. If this assumption does not hold, users may get incorrect responses.
	# 
	# ##Configuration
	# RS232Devices have addition configuration parameters, which can be placed in the normal {Device::configure}
	# block.
	# 
	# + *port*: the serial port the device is connected to. You shouldn't set this directly, because it
	# 	should be modifiable by the user
	# + *baud*: the baud rate at which communication occurs. You can either set this, if the device uses a
	# 	fixed baud rate, or let the user set it if the device supports variable baud rates
	# + *data_bits*: the number of data bits used by the device (usually 7 or 8)
	# + *stop_bits*: the number of stop bits used by the device (either 1 or 2)
	# + *parity*: the kind of parity checking used; can be 0, 1 or 2 which are NONE, EVEN and ODD respectively
	# + *message_end*: the character(s) which demarcate the end of a message; for ASCII-based protocols usually
	# 	a newline ("\n") or a carriage return and newline ("\r\n"). You must set this if you want message
	# 	interpretation to work correctly.
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
		
		# @private
		# @return The array of responses created by calls do {RS232Device::responses}
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
		
		# Starts a requests block, wherein statements describing the various requests that should
		# be made of the device are placed. Many devices do not proactively report state changes
		# to their controller and need to be constantly polled to determine whether anything has
		# changed. In order to provide the user a feeling of control, it is important that the
		# current system state always reflect the device's real state as closely as possible.
		# For example, the default touchscreen interface does not allow you to turn on a projector
		# that is already on. However, if the controller does not poll for the power state, the
		# projector could be manually turned off and the controller would be unaware. Now, the
		# projector is off but the system still thinks it's on, and the user is unable to turn it
		# back on using the touchscreen.
		# 
		# Creating requests is very simple. Each request needs three things: a name, the string to
		# send, and its priority compared to other requests. The priority is a floating point number
		# which determines how often the request is sent. If we have two requests, A with priority 1.0
		# and B with priority 0.5, request A will be sent roughly twice as often as request B. The
		# numbers are entirely relative, so you can use whatever scale you like. The system will send
		# a request whenever the channel is clear (we are not waiting for a response) and there are
		# no commands waiting to be sent, so user commands are still prioritized but states are kept
		# as up to date as possible. When requests are defined a vector is created with the sequence
		# of requests to send. Every time a request can be sent, the next request is taken from this
		# vector. The number of copies of each request in this vector is determined by the priorities.
		# In essence, we scale all of the priorities such that the smallest is one; these scaled
		# priorities are then the number of copies. We then interleave them as much as possible so that
		# there is a regular spacing between requests.
		# @example
		# 	requests do
		# 		send :input,  "I\r\n", 1.5
		# 		send :volume, "V\r\n", 0.5
		# 		send :mute,   "Z\r\n", 1.0
		# 	end
		# 	# The requests vector created by these priorities is as follows
		# 	[:input, :volume, :mute, :input, :mute, :input]
		def self.requests &block
			rh = RequestHandler.new
			rh.instance_eval(&block)
			@_requests ||= []
			@_requests += rh.requests
			@_request_scheduler = []
			#The multiplier is the number which scales everything such that the smallest is 1.0
			multiplier = 1.0/@_requests.collect{|x| x[2]}.min
			#Multiply all of the priorities by the multiplier
			r = @_requests.collect{|x| [x[0], x[1], (x[2]*multiplier).to_i]}
			iter = 0
			r.inject(0){|sum, x|x[2] + sum}.times{|i|
				while r[iter % r.size][2] == 0
					iter += 1
				end
				r[iter % r.size][2] -= 1
				@_request_scheduler << r[iter % r.size]
				iter += 1
			}
		end
		
		# @private
		# @return The vector of requests created by a {RS232Device::requests} block
		def request_scheduler
			self.class.instance_variable_get(:@_request_scheduler)
		end
		
		# @private
		# Reads in each block of data from EM::Serialport, and processes it by splitting it into
		# discrete messages by means of message_end, then matching each message against the
		# responses that have been defined by {RS232::responses}. If one is matched, its handler
		# is called and the result is sent back to the user or ignored. Also sets ready_to_send,
		# which causes the next request or command to be sent.
		def read data
			@_buffer ||= ""
			@_responses ||= {}
			@_buffer << data
			s = StringScanner.new(@_buffer)
			handle_message = proc {
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
			}
			#if message_end is a string, we scan through the buffer for message_end
			if configuration[:message_end].is_a? String
				while msg = s.scan(/.+?#{configuration[:message_end]}/) do
					msg.gsub!(configuration[:message_end], "")
					handle_message.call
				end
			elsif configuration[:message_end].is_a? Proc
				@_buffer.each_index{|i|
					configuration[:message_end].call(@_buffer[0..i])
				}
			end
			@_buffer = s.rest
			#if we got the message end signal, we're safe to send the next thing
			if data.match(configuration[:message_end])
				self.ready_to_send = true
			end
		end
		
		# @private
		# When set to true, sends the next thing in the send queue or the next request if send_queue
		# is empty. When set to false, will set itself to true if {RS232Device::TIMEOUT} seconds have
		# passed sent the last message was sent.
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

		# @private
		# @return [Boolean] whether or not the device is ready for new messages
		def ready_to_send; @_ready_to_send; end
		
		# @private
		# Sends the next message in the send queue and sets ready\_to\_send to false.
		def send_from_queue
			if message = @_send_queue.pop
				@_last_sent_time = Time.now
				@_ready_to_send = false
				@_message_handler = message[1] ? message[1] : EM::DefaultDeferrable.new
				@_message_handler.timeout(TIMEOUT)
				send_string message[0]
			end
		end
		
		# @private
		# Chooses the next request to send by iterating circularly through the request vector
		def choose_request
			return nil unless request_scheduler
			@_request_iter ||= -1
			@_request_iter += 1
			request_scheduler[@_request_iter % request_scheduler.size][1]
		end
		
	end
end

# @private
# Creates an EM::Connection for use with EM::Serialport. Because the main RS232Device class must
# subclass from Device, it cannot subclass from EM::Connection. Therefore, we must create a dummy
# connection subclass to use instead. All it does is call @receiver.read when data is received,
# where @receiver is automatically set to the RS232Device subclass.
class RS232Connection < EM::Connection
	def initialize
		@receiver ||= self.class.instance_variable_get(:@receiver)
		@receiver.serialport = self
	end
	def receive_data data
		@receiver.read data if @receiver
	end	
end
