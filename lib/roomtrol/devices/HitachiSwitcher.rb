#---
#{
#	"name": "HitachiSwitcher",
#	"depends_on": "VideoSwitcher",
#	"description": "Controls Hitachi video switcher",
#	"author": "Sam Giagtzoglou",
#	"email": "sgiagtzoglou@wesleyan.edu"
#}
#---

class HitachiSwitcher < SocketVideoSwitcher
	configure do 
		DaemonKit.logger.info "@Initializing HitachiSwitcher at URI #{options[:uri]} with name #{name}"
		48.times { 
			send_string("\xBE\xEF\x03\x06\x00\xFE\xD2\x01\x00\x00\x20\x00\x00") #Sets the unused mic volume to 0 to avoid hardware error where input audio is picked up by the mic
			ack #Waits for a response from device before sending next command
		}

	end
	#Hitachi uses hex commands for set and get commands
	inputCommand = ["\xBE\xEF\x03\x06\x00\xFE\xD2\x01\x00\x00\x20\x00\x00",
			"\xBE\xEF\x03\x06\x00\x3E\xD0\x01\x00\x00\x20\x04\x00",
			"\xBE\xEF\x03\x06\x00\x0E\xD2\x01\x00\x00\x20\x03\x00",
			"\xBE\xEF\x03\x06\x00\x6E\xD6\x01\x00\x00\x20\x0D\x00",
			"\xBE\xEF\x03\x06\x00\x9E\xD6\x01\x00\x00\x20\x0E\x00",
			"\xBE\xEF\x03\x06\x00\x3E\xDF\x01\x00\x00\x20\x10\x00"] #Array of input set commands

	inputGet = {"x20\x00\x00" => 1,
				"x20\x04\x00" => 2,
				"x20\x03\x00" => 3,
				"x20\x0D\x00" => 4,
				"x20\x0E\x00" => 5,
				"x20\x10\x00" => 6} #Matches the get input command back to an input number
	
	managed_state_var :input,
    	:type => :option,
    	:display_order => 1,
    	:options => ("1".."6").to_a,
    	:response => :channel,
    	:action => proc{|input|
    		#DaemonKit.logger.info "Current input: " + self.input ". Changing input to " + input
      		send_string inputCommand[input-1]  #Sends corresponding source command
    	}
	managed_state_var :volume,
		:type => :percentage,
		:display_order => 2,
		:response => :volume,
		:action => proc{|volume|
			#DaemonKit.logger.info "Current volume: " + @volume ". Increasing volume to " + volume
			@volume.upto(volume) do #Increments volume up to inputed volume
    			send_string "\xBE\xEF\x03\x06\x00\xAB\xC3\x04\x00\x50\x20\x00\x00" 
        		ack #Waits for a response from device before sending next command
        	end
			#DaemonKit.logger.info "Current volume: " + @volume ". Decreasing volume to " + volume
			volume.upto(@volume) do #Decrements volume down to inputed volume
    			send_string "\xBE\xEF\x03\x06\x00\x7A\xC2\x05\x00\x50\x20\x00\x00" 
        		ack #Waits for a response from device before sending next command
        	end
		}
	managed_state_var :mute,
		:type => :boolean,
		:display_order => 3,
		:response => :mute,
		:action => proc{|on|
			#DaemonKit.logger.info "Current mute: " + @mute ". Changing mute to " + on
			on ? send_string "\xBE\xEF\x03\x06\x00\xD6\xD2\x01\x00\x02\x20\x01\x00" : send_string("\xBE\xEF\x03\x06\x00\x46\xD3\x01\x00\x02\x20\x00\x00") #Sends mute or unmute command
		}
	
	responses do
		self.input = inputGet[:input]+1
		self.volume = :volume[1].unpack('C')[0] #Recieves packet and decodes hex to get int for volume 0-48
		self.mute = (:mute[1].unpack('C')[0] == 1) #Recieves packet and decodes hex to get bool for mute
	end

	requests do
		send :input, "\xBE\xEF\x03\x06\x00\xCD\xD2\x02\x00\x00\x20\x00\x00", 1
		send :volume,"\xBE\xEF\x03\x06\x00\xCD\xC3\x02\x00\x50\x20\x00\x00", 1
		send :mute,  "\xBE\xEF\x03\x06\x00\x75\xD3\x02\x00\x02\x20\x00\x00", 1
	end
end