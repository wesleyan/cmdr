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
    # the mute implementation on the device is kind of useless for
    # our purposes, because it loses mute when volume changes and
    # because there is no way to query mute status. so we're going
    # to emulate mute by setting volume to 0.
    if on
      @fake_mute = true
      this.mute = true
      @old_vol = this.volume
      "700%"
    else
      @fake_mute = false
      this.mute = false
      "7#{"%02" % (@old_vol * 60)}%"
    end
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

  responses do
    match :mode, /([STEREO|MONO]) MODE/, proc{|m| self.mode = m[1]}
    match :input, /A: (\d) -> 1/, proc{|m| self.input = m[1]}
    match :mic_volume, /Volume of MIC : (\d\d)/, proc{|m| self.mic_volume = m[1].to_i/60.0}
    match :volume, /Volume of LINE : (\d\d)/, proc{|m| self.volume = m[1].to_i/60.0}
    match :mute, "Mute Audio", proc{ self.mute = true }
    match :unmute, "UnMute Audio", proc{ self.mute = false }
  end

  requests do
    send :status, "600%", 1
  end
end
