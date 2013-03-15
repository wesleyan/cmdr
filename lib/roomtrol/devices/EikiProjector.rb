#---
#{
#	"name": "EpsonProjector",
#	"depends_on": "Projector",
#	"description": "Controls Epson PowerLite Pro G5750WU",
#	"author": "Micah Wylde",
#	"email": "mwylde@wesleyan.edu"
#}
#---

class EikiProjector < Projector  
  INPUT_HASH = {"RGB1" => 1, "RGB2" => 2, "VIDEO" => 6, "SVIDEO" => 11}

  configure do
    DaemonKit.logger.info "@Initializing projector on port #{options[:port]} with name #{name}"
    port :type => :port
    baud :type => :integer, :default => 19200
    data_bits 8
    stop_bits 1
    parity 0
    message_end "\r"
    message_timeout 2.0
  end

  managed_state_var :power, 
    :type => :boolean,
    :display_order => 1,
    :action => proc{|on|
       "C#{on ? "00" : "01"}\r"
	}
	
	managed_state_var :input, 
		:type => :option,
		# Numbers correspond to HDMI, YPBR, RGB, RGB2, VID, and SVID in that order
		:options => ['RGB1', 'RGB2', 'VIDEO', 'SVIDEO'] 
		:display_order => 2,
		:action => proc{|source|
			"C#{INPUT_HASH[source]}\r"
		}

	managed_state_var :video_mute,
		:type => :boolean,
		:display_order => 4,
		:action => proc{|on|
			"C#{on ? "0D" : "0E"}\r"
		}
		
	responses do
		ack ""
		error :general_error, "?\r", "Received an error"
		match :power,  /(\d\d)/, proc{|m|
	  		DaemonKit.logger.info "Received power value #{m[1]}"
			self.power = (m[1] == "00")
			self.cooling = (m[1] == "20")
			self.warming = (m[1] == "40")	
		}
		match :video_mute, /0(0|1)/, proc{|m| self.video_mute = (m[1] == "1")}
		match :input,      /(\d)/, proc{|m| self.input = m[1]}
	end
	
	requests do
           send :power, "CR0\r", 1
           send :source, "CR1\r", 1
           send :mute, "CRA\r", 1
           send :lamp_usage, "CR3\r", 0.1
	end

  
end
