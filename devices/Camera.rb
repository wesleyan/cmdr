#---
#{
#	"name": "Camera",
#	"inherits": "RS232Device",
#	"description": "The base class for all camera devices; never instantiated",
#	"author": "Micah Wylde",
#	"email": "mwylde@wesleyan.edu",
#	"abstract": true
#}
#---

class Camera < Wescontrol::RS232Device
	
	state_var :power, 		:type => :boolean, :display_order => 1
	state_var :video_mute, 	:type => :boolean, :display_order => 4
	state_var :input, 		:type => :option, :options => ['RGB1','RGB2','VIDEO','SVIDEO'], :display_order => 2
	state_var :brightness,	:type => :percentage, :display_order => 3
	state_var :cooling,		:type => :boolean, :editable => false
	state_var :warming,		:type => :boolean, :editable => false
	state_var :model,		:type => :string, :editable => false
	state_var :lamp_hours,	:type => :number, :editable => false
	state_var :filter_hours,:type => :number, :editable => false
	state_var :percent_lamp_used, :type => :percentage, :editable => false

end