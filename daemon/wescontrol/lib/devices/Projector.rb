#require "#{File.dirname(__FILE__)}/wescontrol/RS232Device"

class Projector < Wescontrol::RS232Device

	@interface = "Projector"

	state_var :power, 		:kind => 'boolean'
	state_var :video_mute, 	:kind => 'boolean'
	state_var :input, 		:kind => 'option', :options => ['RGB1','RGB2','VIDEO','SVIDEO']
	state_var :brightness,	:kind => 'percentage'
	state_var :cooling,		:kind => 'boolean', :editable => false
	state_var :warming,		:kind => 'boolean', :editable => false
	state_var :model,		:kind => 'string', :editable => false
	state_var :lamp_hours,	:kind => 'number', :editable => false
	state_var :filter_hours,:kind => 'number', :editable => false
	state_var :percent_lamp_used, :kind => 'percentage', :editable => false

end
