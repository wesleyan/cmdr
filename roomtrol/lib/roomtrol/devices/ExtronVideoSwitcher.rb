class ExtronVideoSwitcher < Wescontrol::ManagedRS232Device
	def save; puts "Saved"; end
	configure do
		baud        9600
		message_end "\r"
	end
	
	state_var :input, 
		:type => :option, 
		:display_order => 1, 
		:options => ("1".."6").to_a,
		:response => :channel,
		:action => proc{|input|
			"#{input}!"
		}
	state_var :volume,
		:type => :percentage,
		:display_order => 2,
		:response => :volume,
		:action => proc{|volume|
			"#{(volume*100).to_i}V"
		}
	state_var :mute,
		:type => :boolean,
		:display_order => 3,
		:response => :mute,
		:action => proc{|on|
			on ? "1Z\r\n" : "0Z"
		}
	
	state_var :model, :type => 'string', :editable => false
	state_var :firmware_version, :type => 'string', :editable => false
	state_var :part_number, :type => 'string', :editable => false
	state_var :clipping, :type => 'boolean', :display_order => 4, :editable => false
	
	responses do
		match :channel,  /Chn\d/, proc{|r| self.input = r.strip[-1].to_i.to_s}
		match :volume,   /Vol\d+/, proc{|r| self.volume = r.strip[3..-1].to_i/100.0}
		match :mute,     /Amt\d+/, proc{|r| self.mute = r[-1] == "1"}
		match :status,   /Vid\d+ Aud\d+ Clp\d/, proc{|r|
			input = r.scan(/Vid\d+/).join("")[3..-1].to_i
			self.input = input if input > 0
			self.clipping = r.scan(/Clp\d+/).join("")[3..-1] == "1"
		}
	end
	
	requests do
		send :input, "I\r\n", 0.5
		send :volume, "V\r\n", 0.5
		send :mute, "Z\r\n", 0.5
	end
end