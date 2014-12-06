# Copyright (C) 2014 Wesleyan University
#
# This file is part of cmdr-devices.
#
# cmdr-devices is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# cmdr-devices is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with cmdr-devices. If not, see <http://www.gnu.org/licenses/>.

#---
#{
# "name": "ATPA100",
# "depends_on": "RS232Device",
# "description": "Controls Atlona AT-PA 100 amplifiers.",
# "author": "Micah Wylde",
# "email": "mwylde@wesleyan.edu"
#}
#---

class ATPA100 < Cmdr::RS232Device
  def initialize(name,opts)
  configure do
    baud 9600
    message_end "\r\n"
    message_delay 0.1
  end
	  super(name,opts)
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
