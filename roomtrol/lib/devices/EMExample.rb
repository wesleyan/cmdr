class ExtronVideoSwitcherHandler < EM::Connection
	ERRORS = {
		"E01" => "Invalid input channel number",
		"E10" => "Invalid command",
		"E13" => "Invalid value",
		"E14" => "Invalid for this configuration"
	}
	
	def post_init
		@buffer = ""
		@commands = {
			#format is :name => [command, response_detector, callback]
			#The response_detector is a block that, when passed the response string, returns true if
			#the response was for that command
			:set_input		=> [proc {|input| "#{input}!"}, proc {|r| r[0..2] == "Chn"}, proc {|r| self.input = r[-1..-1].to_i.to_s}],
			:set_volume		=> [proc {|volume| "#{(volume*100).to_i}V"}, proc {|r| r[0..2] == "Vol"}, proc {|r| self.volume = r[3..-1].to_i/100.0}],
			:set_mute		=> [proc {|on| on ? "1Z" : "0Z"}, proc {|r| r[0..2] == "Amt"}, proc {|r| self.mute = r[-1..-1] == "1"}],
			:get_status		=> ["I", proc {|r| r.scan(/Vid\d+ Aud\d+ Clp\d/).size > 0}, proc {|r|
				input = r.scan(/Vid\d+/).join("")[3..-1].to_i
				self.input = input if input > 0
				self.clipping = r.scan(/Clp\d+/).join("")[3..-1] == "1"
			}],
			:get_volume		=> ["V", nil, nil], #the response code for setting volume will handle these messages as well
			:get_audio_mute	=> ["Z", nil, nil] #same with this
		}
	end
	
	def receive_data data
		lines = (@buffer + data).split("\r\n")
		@buffer = lines.pop if data[-1] != "\n" || 10 #preserve 1.8 compatibility
		lines.each{|line| interpret_response line}
	end
	
	def interpet_response response
		if ERRORS[response]
			puts "Extron Error: #{response}"
		else
			command = nil
			@commands.each{|key, value|
				command = value if value[1] && value[1].call(response)
			}
			if command
				begin
					@responses[command[0]] = command[2].call(response)
				rescue
					puts "Error in ExtronVideoSwitcher: #{$!}"
				end
			end
		end
	end
end
