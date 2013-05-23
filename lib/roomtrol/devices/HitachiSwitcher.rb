#---
#{
#	"name": "ExtronVideoSwitcher",
#	"depends_on": "VideoSwitcher",
#	"description": "Controls Extron video switchers that support SIS",
#	"author": "Micah Wylde",
#	"email": "mwylde@wesleyan.edu"
#}
#---

class HitachiSwitcher < SocketVideoSwitcher
	configure do 
		
		
	end
	inputCommand = ["\xBE\xEF\x03\x06\x00\xFE\xD2\x01\x00\x00\x20\x00\x00",
			"\xBE\xEF\x03\x06\x00\x3E\xD0\x01\x00\x00\x20\x04\x00",
			"\xBE\xEF\x03\x06\x00\x0E\xD2\x01\x00\x00\x20\x03\x00",
			"\xBE\xEF\x03\x06\x00\x6E\xD6\x01\x00\x00\x20\x0D\x00",
			"\xBE\xEF\x03\x06\x00\x9E\xD6\x01\x00\x00\x20\x0E\x00",
			"\xBE\xEF\x03\x06\x00\x3E\xDF\x01\x00\x00\x20\x10\x00"]
	managed_state_var :input,
    	:type => :option,
    	:display_order => 2,
    	:options => ("1".."6").to_a,
    	:response => :channel,
    	:action => proc{|input|
      		inputCommand[input-1]
    	}
	managed_state_var :volume,
		:type => :percentage,
		:display_order => 4,
		:response => :volume,
		:action => proc{|volume|
			"q#{(volume*100).to_i}V"
		}
	managed_state_var :mute,
		:type => :boolean,
		:display_order => 5,
		:response => :mute,
		:action => proc{|on|
			on ? "q1Z" : "q0Z"
		}
	
	

	inputGet = {"x20\x00\x00" => 1,
				"x20\x04\x00" => 2,
				"x20\x03\x00" => 3,
				"x20\x0D\x00" => 4,
				"x20\x0E\x00" => 5,
				"x20\x10\x00" => 6}
	
	responses do
		self.input = inputGet[:input]
		self.volume = :volume[1].unpack('C')[0]


	end


	requests do
		send :input, "\xBE\xEF\x03\x06\x00\xCD\xD2\x02\x00\x00\x20\x00\x00", 1
		send :volume,"\xBE\xEF\x03\x06\x00\xCD\xC3\x02\x00\x50\x20\x00\x00", 1
	end

end