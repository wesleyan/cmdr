#---
#{
#	"name": "AT-PA 100",
#	"depends_on": "RS232Device",
#	"description": "Controls Atlona AT-PA 100 amplifiers.",
#	"author": "Micah Wylde",
#	"email": "mwylde@wesleyan.edu"
#}
#---

class ATPA100 < Wescontrol::RS232Device
  configure do
    baud 9600
    message_end "\r\n"
    message_delay 0.1
  end

  managed_state_var :mute,
  :type => :boolean,
  :display_order => 3,
  :action => proc{|on|
    "OA#{on ? 0 : 1}."
  }

  def volume=
    super unless @fake_mute
  end
  
  managed_state_var :mic_volume,
  :type => :percentage,
  :display_order => 2,
  :action => proc{|vol|
    "5#{"%02d" % (vol * 60)}%"
  }

  managed_state_var :volume,
  :type => :percentage,
  :display_order => 1,
  :action => proc{|vol|
    # handles mute turning off on volume change
    self.mute = false if self.mute
    "7#{"%02d" % (vol * 60)}%"
  }

  managed_state_var :input,
  :type => :option,
  :options => ("1".."2").to_a,
  :display_order => 4,
  :action => proc{|input|
    "#{input}A1."
  }

  state_var :mode, :type => :string, :editable => false
  state_var :operational, :type => :boolean

  responses do
    match :mode, /([STEREO|MONO]) MODE/, proc{|m| self.mode = m[1]}
    match :input, /A: (\d) -> 1/, proc{|m| self.input = m[1]}
    match :mic_volume, /Volume of MIC : (\d\d)/, proc{|m| self.mic_volume = m[1].to_i/60.0}
    match :volume, /Volume of LINE : (\d\d)/, proc{|m| self.volume = m[1].to_i/60.0}
    match :unmute, /UnMute Audio/, proc{ self.mute = false }
    match :mute, /Mute Audio/, proc{ self.mute = true }
  end

  requests do
    send :status, "600%", 1
  end
end
