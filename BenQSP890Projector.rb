#---
#{
#	"name": "BenQSP890Projector",
#	"depends_on": "Projector",
#	"description": "Controls BenQ SP890 projector. Should also work with MP722, Mp723, MP771 and SP870",
#	"author": "Micah Wylde",
#	"email": "mwylde@wesleyan.edu"
#}
#---

class BenQSP890Projector < Projector
	configure do
		baud           115200
		message_format(/\r\*(.*)#\r/)
	end
	
	managed_state_var :power, 
		:type => :boolean,
		:display_order => 1,
		:action => proc{|on|
			"\r*pow=#{on ? "on" : "off"}#\r"
		}
	
	managed_state_var :input, 
		:type => :option,
		:options => ['VGA', 'DVI', 'COMP', 'SVID'],
		:display_order => 2,
		:action => proc{|source|
			"\r*sour=#{source}#\r"
		}

	managed_state_var :mute, 
		:type => :boolean,
		:action => proc{|on|
			"\r*mute=#{on ? "on" : "off"}#\r"
		}
	
	managed_state_var :video_mute,
		:type => :boolean,
		:display_order => 4,
		:action => proc{|on|
			"\r*blank=#{on ? "on" : "off"}#\r"
		}
		
	responses do
		match :power,  /pow=(.+)/, proc{|m| 
			self.power = (m[1] == "on")
			self.cooling = (m[1] == "cool down")
		}
		match :mute,       /mute=(.+)/, proc{|m| self.mute = (m[1] == "on"})
		match :video_mute, /blank=(.+)/, proc{|m| self.video_mute = (m[1] == "on")}
		match :input,      /sour=(.+)/, proc{|m| self.input = m[1]}
	end
	
	requests do
		#send :power, "\r*pow=?#\r", 1
	end
	
end