#---
#{
#	"name": "VideoSwitcher",
#	"depends_on": "RS232Device",
#	"description": "Generic class for videoswitchers.",
#	"author": "Micah Wylde",
#	"email": "mwylde@wesleyan.edu",
#	"abstract": true,
#	"type": "Video Switcher"
#}
#---

class SocketVideoSwitcher < Wescontrol::SocketDevice
	#state_var :input, :type => :option, :display_order => 1, :options => ("1".."6").to_a
  state_var :video, :type => :option, :display_order => 1, :options => ("1".."6").to_a
  state_var :audio, :type => :option, :display_order => 2, :options => ("1".."6").to_a
	state_var :volume, :type => :percentage, :display_order => 3
	state_var :mute, :type => :boolean, :display_order => 4
	state_var :operational, :type => :boolean
end
