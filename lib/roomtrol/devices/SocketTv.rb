#---
#{
# "name": "SocketTv",
# "depends_on": "SocketDevice",
# "description": "Generic class to control TV over a TCP connection. The class is modified to simulate a projector",
# "author": "Justin Raymond",
# "email": "jraymond@wesleyan.edu",
# "abstract": true,
# "type": "Tv"
#}
#---

class SocketTv < Wescontrol::SocketDevice

  @interface = "Tv"

  state_var :power, :type => :boolean, :display_order => 1
	state_var :operational, :type => :boolean
	
	#The following state vars are only to simulate a projector
	state_var :video_mute, :type => :boolean
	state_var :brightness, :type => :percentage
  state_var :operational, :type => :boolean  
	state_var :cooling, :type => :boolean, :editable => false
	state_var :warming, :type => :boolean, :editable => false
	state_var :model, :type => :string, :editable => false
	state_var :lamp_hours, :type => :number, :editable => false
	state_var :filter_hours,:type => :number, :editable => false
	state_var :percent_lamp_used, :type => :percentage, :editable => false
	
	virtual_var :lamp_remaining, :type => :string, :depends_on => [:lamp_hours, :percent_lamp_used], :transformation => proc {
		"#{((lamp_hours/percent_lamp_used - lamp_hours)/(60*60.0)).round(1)} hours"
	}
	
	virtual_var :state, :type => :string, :depends_on => [:power, :warming, :cooling, :video_mute], :transformation => proc {
		warming ? "warming" :
			cooling ? "cooling" :
				!power ? "off" :
					video_mute ? "muted" : "on"	    
	}
  
end

