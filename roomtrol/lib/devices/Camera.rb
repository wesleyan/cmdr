class Camera < Wescontrol::RS232Device
	
	state_var :power, 		:kind => 'boolean', :display_order => 1
	state_var :video_mute, 	:kind => 'boolean', :display_order => 4
	state_var :input, 		:kind => 'option', :options => ['RGB1','RGB2','VIDEO','SVIDEO'], :display_order => 2
	state_var :brightness,	:kind => 'percentage', :display_order => 3
	state_var :cooling,		:kind => 'boolean', :editable => false
	state_var :warming,		:kind => 'boolean', :editable => false
	state_var :model,		:kind => 'string', :editable => false
	state_var :lamp_hours,	:kind => 'number', :editable => false
	state_var :filter_hours,:kind => 'number', :editable => false
	state_var :percent_lamp_used, :kind => 'percentage', :editable => false

end