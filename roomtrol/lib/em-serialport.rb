$eventmachine_library = :pure_ruby # need to force pure ruby

require 'eventmachine'
require 'serialport'

module EventMachine
	class EvmaSerialPort < StreamObject
		def self.open(dev, baud, databits, stopbits, parity)
			io = SerialPort.new(dev, baud, databits, stopbits, parity)
			return(EvmaSerialPort.new(io))
		end

		def initialize(io)
			super
		end

		##
		# Monkeypatched version of EventMachine::StreamObject#eventable_read so
		# that EOFErrors from the SerialPort object (which the ruby-serialport
		# library uses to signal the fact that there is no more data available
		# for reading) do not cause the connection to unbind.
		def eventable_read
			@last_activity = Reactor.instance.current_loop_time
			begin
				if io.respond_to?(:read_nonblock)
					10.times {
						data = io.read_nonblock(4096)
						EventMachine::event_callback uuid, ConnectionData, data
					}
				else
					data = io.sysread(4096)
					EventMachine::event_callback uuid, ConnectionData, data
				end
			rescue Errno::EAGAIN, Errno::EWOULDBLOCK, EOFError
				# no-op
			rescue Errno::ECONNRESET, Errno::ECONNREFUSED
				@close_scheduled = true
				EventMachine::event_callback uuid, ConnectionUnbound, nil
			end
		end
	end

	class << self
		def connect_serial(dev, baud, databits, stopbits, parity)
			EvmaSerialPort.open(dev, baud, databits, stopbits, parity).uuid
		end
	end

	def EventMachine::open_serial(dev, baud, databits, stopbits, parity,
																handler=nil)
		klass = if (handler and handler.is_a?(Class))
					handler
				else
					Class.new( Connection ) {handler and include handler}
				end
		s = connect_serial(dev, baud, databits, stopbits, parity)
		c = klass.new s
		@conns[s] = c
		block_given? and yield c
		c
	end

	class Connection
		# This seems to be necessary with EventMachine 0.12.x
		def associate_callback_target(sig)
			return(nil)
		end
	end
end

#Example:
#class Echo < EM::Connection
#    def receive_data data
#        puts data
#        send_data("Got: #{data}")
#    end
#end
#EM::run { EM::open_serial "/dev/master", 9600, 8, 1, 0, Echo}
