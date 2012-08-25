#---
#{
#	"name": "PJLinkProjector",
#	"depends_on": "SocketProjector",
#	"description": "Controls any projector capable of understanding the PJLink protocol standard, ie. the Epson PowerLite Pro G5750WU",
#	"author": "Jonathan Lyons",
#	"email": "jclyons@wesleyan.edu"
#}
#---

class PJLinkProjector < SocketProjector  
  INPUT_HASH = {"HDMI" => 30, "YPBR" => 14, "RGB1" =>  11, "VIDEO" => 41, "SVIDEO" => 42}

  configure do
    DaemonKit.logger.info "@Initializing PJLinkProjector at URI #{options[:uri]} with name #{name}"
  end

  def read data
    EM.cancel_timer @_cooling_timer if @_cooling_timer
    @_cooling_timer = nil
    super data
  end

	managed_state_var :power, 
		:type => :boolean,
		:display_order => 1,
		:action => proc{|on|
      "PWR #{on ? "ON" : "OFF"}\r\r"
		}
	
	managed_state_var :input, 
		:type => :option,
		# Numbers correspond to HDMI, YPBR, RGB, RGB2, VID, and SVID in that order
		:options => [ 'HDMI', 'YPBR', 'RGB1', 'VID', 'SVID'],
		:display_order => 2,
		:action => proc{|source|
			"SOURCE #{INPUT_HASH[source]}\r"
		}

	managed_state_var :mute, 
		:type => :boolean,
		:action => proc{|on|
			"MUTE #{on ? "ON" : "OFF"}\r"
		}
	
	managed_state_var :video_mute,
		:type => :boolean,
		:display_order => 4,
		:action => proc{|on|
			"MUTE #{on ? "ON" : "OFF"}\r"
		}
		
	responses do
		ack ":"
		error :general_error, "ERR", "Received an error"
		match :power,  /%1POWR=(.+)/, proc{|m|
	 		DaemonKit.logger.info "Received power value #{m[1]}"
			  self.power = (m[1] == "1") || (m[1] == "ERR3")
	  		self.cooling = (m[1] == "2")
	  		self.warming = (m[1] == "3")
		}
	#	match :mute,       /MUTE=(.+)/, proc{|m| self.mute = (m[1] == "OFF")}
		match :video_mute, /MUTE=(.+)/, proc{|m| self.video_mute = (m[1] == "ON")}
		match :input,      /SOURCE=(.+)/, proc{|m| self.input = m[1]}
		
	end
	
	requests do
           send :power, "PWR?\r", 1
           send :source, "SOURCE?\r", 1
           send :mute, "MUTE?\r", 1
           send :lamp_usage, "*ltim=?#", 0.1
	end

  
end
