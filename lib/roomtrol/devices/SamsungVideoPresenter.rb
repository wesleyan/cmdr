#---
#{
#	"name": "SamsungVideoPresenter",
#	"depends_on": "RS232Device",
#	"description": "Samsung Video Presenter.",
#	"author": "Micah Wylde",
#	"email": "mwylde@wesleyan.edu",
#	"abstract": true,
#	"type": "VideoPresenter"
#}
#---

class SamsungVideoPresenter < Wescontrol::RS232Device
	configure do
		#Check baudrate, parity bit, stop bit length
	end
	
	state_var :power,       :type => :boolean, :display_order => 1#, :on_change => proc{|on|
	
	#sudo minicom -b 4800 -D /dev/ttyUSB#

	managed_state_var :power,
		:type => :boolean,
		:display_order => 1,
		:action => proc{|on|
			""
		}
	responses do


	end

	requests do


	end

end
