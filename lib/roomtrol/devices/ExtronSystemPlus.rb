#---
#{
#	"name": "ExtronSystemPlus",
#	"depends_on": "SocketVideoSwitcher",
#	"description": "Controls System 8 Plus and System 10 Plus Extrons, as well as the IN1606 Extron switcher"
#}
#---

class ExtronSystemPlus < SocketVideoSwitcher
	configure do
    DaemonKit.logger.info "@initializing SocketExtron at URI #{options[:uri]} with name #{name}"
	end
	
  managed_state_var :video,
    :type => :option,
    :display_order => 1,
    :options => ("1".."6").to_a,
    :response => :channel,
    :action => proc{|input|
      "#{input}&"
    }
  managed_state_var :audio,
    :type => :option,
    :display_order => 2,
    :options => ("1".."6").to_a,
    :response => :channel,
    :action => proc{|input|
      "#{input}$"
    }
	managed_state_var :mute,
		:type => :boolean,
		:display_order => 3,
		:response => :mute,
		:action => proc{|on|
			on ? "+" : "-"
		}
	
	state_var :model, :type => 'string', :editable => false
	state_var :firmware_version, :type => 'string', :editable => false
	state_var :part_number, :type => 'string', :editable => false
	state_var :clipping, :type => 'boolean', :display_order => 4, :editable => false
	
	responses do
		match :channel,  /Chn(\d)/, proc{|m| self.input = m[1].to_i.to_s}
		match :volume,   /Vol(\d+)/, proc{|m| self.volume = m[1].to_i/100.0}
		match :status,   /V(\d+) A(\d+) T(\d) P(\d) S(\d) Z(\d) R(\d)/, proc{|m|
      self.video = m[1].to_i if m[1].to_i > 0
      self.audio = m[2].to_i if m[2].to_i > 0
      self.mute = (m[6] == "1")
			#self.clipping = (m[3] == "1")
		}
	end
	
	requests do
    send :video, "I", 0.5
    send :audio, "I", 0.5
	end
end
