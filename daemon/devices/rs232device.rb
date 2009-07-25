require 'rubygems'
require 'devices/device'
require 'serialport'
require 'bitpack'

class RS232Device < Device
	attr_reader :port, :serial_port
		
	#def baud
	#	return @serial_port.baud
	#end	
	def baud=(baud_rate)
		@serial_port.baud = baud_rate
	end
	
	def data_bits
		return @serial_port.data_bits
	end
	def data_bits=(data)
		@serial_port.data_bits = data
	end
	
	def stop_bits
		return @serial_port.stop_bits
	end
	def stop_bits=(stop)
		@serial_port.stop_bits = stop
	end

	def queue_string(string)
		@queue << string
	end

	def send_top_of_queue()
		@serial_port.write(@queue.pop)
	end

	def send_string(string)
		Thread.new{
			@serial_port.write(string)
		}
	end
	
	protected
	def initialize(port, baud_rate, data_bits, stop_bits, name, bus)
		@port = port
		@serial_port = SerialPort.new(port, {:baud_rate => baud_rate, :data_bits => data_bits, :stop_bits => stop_bits})
		@queue = Queue.new
		@messages = Queue.new
		@response = Queue.new
		super(name, bus)
	end
end
