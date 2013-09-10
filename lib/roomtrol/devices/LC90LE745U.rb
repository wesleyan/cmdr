#---
#{
# "name": "LC-90E745U", 
# "depends_on": "SocketTv", 
# "description": "Controls Sharp LC-90E745U TV. The driver is altered so that it simulates a PJLinkProjector", 
# "author": "Justin Raymond", 
# "email": "jraymond@wesleyan.edu" 
#} 
#--- 

class LC90E745U < SocketTv 

  configure do
    DaemonKit.logger.info "@Initializing LC90E745 at URI #{options[:uri]} with name #{@name}"
  end

  #More information about the commands may be found on page 68 of the manual.
  #If 0, the power on command rejected. If on, the power on command accepter. 
  # When the power is in standby mode, commands also go to waiting status and
  # so power consumption is just about the same as usual. With the commands in
  # waiting status, the Center Icon Illumination on the front of the TV lights up.

  #If off tv goes to standby.
  managed_state_var :power,
    :type => :boolean,
    :display_order => 1,
    :action => proc{|on|
      send_string "POWR#{on ? "1" : "0"}   \r"
    }
	
	#variable to simulate projector
	managed_state_var :video_mute,
		:type => :boolean,
		:display_order => 1,
		:action => proc{|on|
			"POWR?   \r"
		}

	#variable to simulate projector
	managed_state_var :input,
		:type => :option,
		:options => [ 'HDMI', 'YPBR', 'RGB1', 'VID', 'SVID'],
		:action => proc{|source|
			"POWR?   \r"
		}

	#variable to simulate projector
	managed_state_var :mute,
		:type => :boolean,
		:action => proc{|on|
			"POWR?   \r"
		}

  responses do
    error :not_ok, /ERR0DH/, "Communication error or incorrect command"
    ack "OK0DH"
    match :power, /(0|1)/, proc{|m|
			self.power = (m[1] == "1")
			DaemonKit.logger.info "TV received power value: #{m[1]}"
	#the following are only to simulate a projector
			self.cooling = (false)
			self.warming = (false)
			self.video_mute = (false)
		}
		match :video_mute, /foo/, proc{|m| self.video_mute = (false)}
		match :input, /bar/, proc{|m| self.input = 'hdmi'}
	end

  requests do
    send :power,     "POWR?   \r", 1
  end

end
