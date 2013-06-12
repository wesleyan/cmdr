#---
#{
#	"name": "ExtronDXP",
#	"depends_on": "MultiSocketVideoSwitcher",
#	"description": "Controls the Extron DXP multi output video switcher"
#   "author": "Sam Giagtzoglou",
#	"email": "sgiagtzoglou@wesleyan.edu",
#}
#---
#This driver requires the multi projector wescontrol_websocket.rb
class ExtronDXP < MultiSocketVideoSwitcher
	configure do
    DaemonKit.logger.info "@initializing MultiSocketExtron at URI #{options[:uri]} with name #{name}"
    send_string("1X")
    @audioOut = 4 #HDMI to offload all audio to

	end
	
  managed_state_var :video,
    :type => :option,
    :display_order => 1,
    :options => ['[1,1]', '[1,2]', '[1,3]', '[1,4]', '[2,1]', '[2,2]', '[2,3]', '[2,4]', '[3,1]', '[3,2]', '[3,3]', '[3,4]','[4,1]', '[4,2]', '[4,3]', '[4,4]'],
    :response => :channel,
    :action => proc{|input|
      #{}"#{input}&"
	"#{input[0]}*#{input[1]}%"
    }
  managed_state_var :audio,
    :type => :option,
    :display_order => 2,
    :options => ["[1,1]", "[1,2]", "[1,3]", "[1,4]", "[2,1]", "[2,2]", "[2,3]", "[2,4]", "[3,1]", "[3,2]", "[3,3]", "[3,4]","[4,1]", "[4,2]", "[4,3]", "[4,4]"],
    :response => :channel,
    :action => proc{|input|
      "#{input[0]}*#{@audioOut}$"
    }
	managed_state_var :mute,
		:type => :boolean,
		:display_order => 3,
		:response => :mute,
		:action => proc{|on|
			on ? "1*Z" : "0*Z"
		}
	
	state_var :model, :type => 'string', :editable => false
	state_var :firmware_version, :type => 'string', :editable => false
	state_var :part_number, :type => 'string', :editable => false
	state_var :clipping, :type => 'boolean', :display_order => 4, :editable => false
	

end
