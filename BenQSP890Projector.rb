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
    message_end(/\n\r|\r\n/)
	end
	
	managed_state_var :power, 
		:type => :boolean,
		:display_order => 1,
		:action => proc{|on|
			"*pow=#{on ? "on" : "off"}#"
		}
	
	managed_state_var :input, 
		:type => :option,
		:options => ['VGA', 'DVI', 'COMP', 'SVID'],
		:display_order => 2,
		:action => proc{|source|
			"*sour=#{source}#"
		}

	managed_state_var :mute, 
		:type => :boolean,
		:action => proc{|on|
			"*mute=#{on ? "on" : "off"}#"
		}
	
	managed_state_var :video_mute,
		:type => :boolean,
		:display_order => 4,
		:action => proc{|on|
			"*blank=#{on ? "on" : "off"}#"
		}
		
	responses do
    ack /\*[a-z]+?=.+#/
		match :power,  /\*POW=(.+)#/, proc{|m| 
			self.power = !(m[1] == "OFF")
			self.cooling = (m[1].downcase == "COOL DOWN")
		}
		match :mute,       /\*MUTE=(.+)#/, proc{|m| self.mute = (m[1] == "ON")}
		match :video_mute, /\*BLANK=(.+)#/, proc{|m| self.video_mute = (m[1] == "ON")}
		match :input,      /\*SOUR=(.+)#/, proc{|m| self.input = m[1]}
	end
	
	requests do
		send :power, "*pow=?#", 1
    send :source, "*sour=?#", 1
    send :mute, "*blank=?#", 1
#    send :lamp_usage, "*ltim=?#", 0.1
	end
	
end
