#require "#{File.dirname(__FILE__)}/wescontrol/RS232Device"

class VideoSwitcher < Wescontrol::RS232Device

	@interface = "VideoSwitcher"
	
	state_var :input, :kind => 'number'
	state_var :volume, :kind => 'percentage'
	state_var :mute, :kind => 'boolean'
	
end
