require 'rubygems'
require 'serialport'
require 'bit-struct'

module Wescontrol
	class RS232Device < Device
		config_var :baud
		config_var :data_bits
		config_var :stop_bits
		config_var :port
		
		#def baud
		#	return @serial_port.baud
		#end	
		def baud=(baud)
			@serial_port.baud = baud
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

		def send_string(string)
			Thread.new{
				@serial_port.write(string)
			}
		end
	
		protected
		def initialize(options)
			options = options.symbolize_keys
			@serial_port = SerialPort.new(options[:port], {:baud => options[:baud], :data_bits => options[:data_bits], :stop_bits => options[:stop_bits]})
			@port = options[:port]
			@baud = options[:baud]
			@data_bits = options[:data_bits]
			@stop_bits = options[:stop_bits]
			super(options)
		end
	end
end
