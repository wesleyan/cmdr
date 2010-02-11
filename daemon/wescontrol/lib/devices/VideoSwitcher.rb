#require "#{File.dirname(__FILE__)}/wescontrol/RS232Device"

class VideoSwitcher < Wescontrol::RS232Device

	@interface = "VideoSwitcher"
	
	state_var :input, :kind => 'number', :display_order => 1
	state_var :volume, :kind => 'percentage', :display_order => 2
	state_var :mute, :kind => 'boolean', :display_order => 3
	
end
