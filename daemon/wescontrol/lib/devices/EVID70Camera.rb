class EVID70Camera
	
	config_var :address
	
	def initialize(options)
		options = options.symbolize_keys
		puts "@Initializing camera on port #{options[:port]} with name #{options[:name]}"
		Thread.abort_on_exception = true
		@address = options[:address]
		
		ERRORS = {
			1 => "Message length error (>14 bytes)",
			2 => "Syntax Error",
			3 => "Command buffer full",
			4 => "Command cancelled",
			5 => "No socket (to be cancelled)",
			0x41 => "Command not executable"
		}
		
		ZOOM = {
			1  => "0000",
			2  => "1606",
			3  => "2151",
			4  => "2860",
			5  => "2CB5",
			6  => "3060",
			7  => "32D3",
			8  => "3545",
			9  => "3727",
			10 => "38A9",
			11 => "3A42",
			12 => "3B4B",
			13 => "3C85",
			14 => "3D75",
			15 => "3E4E",
			16 => "3EF7",
			17 => "3FA0",
			18 => "4000"
		}
		
		@_commands = {
			#name => [message, callback]
			:power => proc{|on| "01 04 00 0" + (on ? "2" : "3")},
			:zoom => proc{|t| p,q,r,s = ZOOM[t].split(""); "01 04 47 0#{p} 0#{q} 0#{r} 0#{s}"},
			:zoom_in => "01 04 07 02",
			:zoom_out => "01 04 07 03",
			:zoom_stop => "01 04 07 00",
			:focus => proc{|f| p = (f * 11 + 1).round.to_s(16); "01 04 48 0#{p} 00 00 00"},
			:focus_near => "01 04 08 03",
			:focus_far => "01 04 08 02",
			:auto_focus => proc{|on| "01 04 38 0" + (on ? "2" : "3")},
			:trigger_auto_focus => "01 04 18 01"
		}
		
		@_ready_to_send = false
		@last_command
	
		super(:port => options[:port], :baud => 9600, :data_bits => 8, :stop_bits => 1, :name => options[:name])
	end
	
	def send message
		bytes = "81FF".hexify
		self.send_string("81 #{message} FF".hexify)
	end

	def read
		buffer = []
		while true do
			buffer << @serial_port.getc
			if buffer[-1] == 0xFF #0xFF terminates each packet
				buffer = buffer[0..-2]
				if buffer == "106Y01".hexify #ACK
					@_ready_to_send = true
				elsif buffer == "105Y".hexify #Command completion
					@_response = true
				elsif buffer[0..1] == "105Y".hexify #Request completion
					@_response = buffer[2..-1]
				elsif buffer[0..1] == "106Y"
					@_error = ERRORS[buffer[2]]
					puts "Camera error: #{@_error}"
				end
				buffer = []
			end
		end
	end
end

class String
	def hexify
		self.gsub(" ", "").scan(/../).collect{|x| x.hex}.pack("c*")
	end
end