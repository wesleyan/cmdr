#---
#{
#	"name": "MultiSocketVideoSwitcher",
#	"depends_on": "SocketDevice",
#	"description": "Class for video switchers with multiple (4) outputs; used for multi projector rooms.",
#	"author": "Sam Giagtzoglou",
#	"email": "sgiagtzoglou@wesleyan.edu",
#	"abstract": true,
#	"type": "Video Switcher"
#}
#---

class MultiSocketVideoSwitcher < Wescontrol::SocketDevice
  state_var :video, :type => :option, :display_order => 1, :options => ["[1,1]", "[1,2]", "[1,3]", "[1,4]", "[2,1]", "[2,2]", "[2,3]", "[2,4]", "[3,1]", "[3,2]", "[3,3]", "[3,4]","[4,1]", "[4,2]", "[4,3]", "[4,4]"]
  state_var :audio, :type => :option, :display_order => 2, :options => ["[1,1]", "[1,2]", "[1,3]", "[1,4]", "[2,1]", "[2,2]", "[2,3]", "[2,4]", "[3,1]", "[3,2]", "[3,3]", "[3,4]","[4,1]", "[4,2]", "[4,3]", "[4,4]"]
	state_var :volume, :type => :percentage, :display_order => 3
	state_var :mute, :type => :boolean, :display_order => 4
	state_var :operational, :type => :boolean
end
