#---
#{
#	"name": "ExtronVideoSwitcher",
#	"depends_on": "VideoSwitcher",
#	"description": "Controls Extron video switchers that support SIS",
#	"author": "Micah Wylde",
#	"email": "mwylde@wesleyan.edu"
#}
#---

class ExtronVideoSwitcher < VideoSwitcher
	configure do
		baud        9600
		message_end "\r\n"
	end
	
	managed_state_var :input, 
		:type => :option, 
		:display_order => 1, 
		:options => ("1".."6").to_a,
		:response => :channel,
		:action => proc{|input|
			"#{input}!\r\n"
		}
	managed_state_var :volume,
		:type => :percentage,
		:display_order => 2,
		:response => :volume,
		:action => proc{|volume|
			"#{(volume*100).to_i}V\r\n"
		}
	managed_state_var :mute,
		:type => :boolean,
		:display_order => 3,
		:response => :mute,
		:action => proc{|on|
			on ? "1Z\r\n" : "0Z\r\n"
		}
	
	state_var :model, :type => 'string', :editable => false
	state_var :firmware_version, :type => 'string', :editable => false
	state_var :part_number, :type => 'string', :editable => false
	state_var :clipping, :type => 'boolean', :display_order => 4, :editable => false
	
	responses do
		match :channel,  /Chn(\d)/, proc{|m| self.input = m[1].to_i.to_s}
		match :volume,   /Vol(\d+)/, proc{|m| self.volume = m[1].to_i/100.0}
		match :mute,     /Amt(\d+)/, proc{|m| self.mute = m[1] == "1"}
		match :status,   /Vid(\d+) Aud(\d+) Clp(\d)/, proc{|m|
			self.input = m[1].to_i if m[1].to_i > 0
			self.clipping = (m[2] == "1")
		}
	end
	
	requests do
		send :input, "I\r\n", 0.5
		send :volume, "V\r\n", 0.5
		send :mute, "Z\r\n", 0.5
	end
end