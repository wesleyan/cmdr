require 'bit-struct'
module Wescontrol
	class RS232Device < Device
		attr_accessor :serialport
		
		configure do
			port :type => :port
			baud :type => :integer, :default => 9600
			data_bits 8
			stop_bits 1
			parity 0
			message_end "\r\n"
		end
	end						
end