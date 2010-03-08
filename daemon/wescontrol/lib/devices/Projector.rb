#require "#{File.dirname(__FILE__)}/wescontrol/RS232Device"

class Projector < Wescontrol::RS232Device

	@interface = "Projector"

	state_var :power, 		:kind => 'boolean', :display_order => 1#, :on_change => proc{|on|
	#	if on
	#		turned_on = Time.now
	#	else
	#		turned_off = Time.now
	#	end
	#}
	state_var :video_mute, 	:kind => 'boolean', :display_order => 4
	state_var :input, 		:kind => 'option', :options => ['RGB1','RGB2','VIDEO','SVIDEO'], :display_order => 2
	state_var :brightness,	:kind => 'percentage', :display_order => 3
	state_var :cooling,		:kind => 'boolean', :editable => false
	state_var :warming,		:kind => 'boolean', :editable => false
	state_var :model,		:kind => 'string', :editable => false
	state_var :lamp_hours,	:kind => 'number', :editable => false
	state_var :filter_hours,:kind => 'number', :editable => false
	state_var :percent_lamp_used, :kind => 'percentage', :editable => false
	#state_var :turned_on,	:kind => 'time', :editable => false
	#state_var :turned_off,	:kind => 'time', :editable => false
	
	virtual_var :lamp_remaining, :kind => 'string', :depends_on => [:lamp_hours, :percent_lamp_used], :transformation => proc {
		"#{((lamp_hours/percent_lamp_used - lamp_hours)/(60*60.0)).round(1)} hours"
	}, :display_order => 6
	
	virtual_var :state, :kind => 'string', :depends_on => [:power, :warming, :cooling, :video_mute], :transformation => proc {
		warming ? "warming" :
			cooling ? "cooling" :
				!power ? "off" :
					video_mute ? "muted" : "on"	    
	}
	
	#time_since_var :on_time, :since => :turned_on, :before => :turned_off
	#virtual_var :on_time, :kind => 'decimal', :depends_on => [:turned_on], :transformation => proc {
	#	(Time.now-turned_on)/(60*60) #Time.- returns seconds; converted to hours
	#}

end
