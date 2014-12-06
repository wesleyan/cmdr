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
# "name": "ExtronSystemPlus",
# "depends_on": "SocketVideoSwitcher",
# "description": "Controls System 8 Plus and System 10 Plus Extrons, as well as the IN1606 Extron switcher",
# "type": "Video Switcher"
#}
#---

class ExtronSystemPlus < SocketVideoSwitcher
#  configure do
    #DaemonKit.logger.info "@initializing SocketExtron at URI #{options[:uri]} with name #{name}"
#  end
  
  managed_state_var :video,
    :type => :option,
    :display_order => 1,
    :options => ("1".."6").to_a,
    :response => :channel,
    :action => proc{|input|
      "#{input}&"
    }
  managed_state_var :audio,
    :type => :option,
    :display_order => 2,
    :options => ("1".."6").to_a,
    :response => :channel,
    :action => proc{|input|
      "#{input}$"
    }
  managed_state_var :mute,
    :type => :boolean,
    :display_order => 3,
    :response => :mute,
    :action => proc{|on|
      on ? "+" : "-"
    }
  
  state_var :model, :type => 'string', :editable => false
  state_var :firmware_version, :type => 'string', :editable => false
  state_var :part_number, :type => 'string', :editable => false
  state_var :clipping, :type => 'boolean', :display_order => 4, :editable => false
  
  responses do
    match :channel,  /Chn(\d)/, proc{|m| self.input = m[1].to_i.to_s}
    match :volume,   /Vol(\d+)/, proc{|m| self.volume = m[1].to_i/100.0}
    match :status,   /V(\d+) A(\d+) T(\d) P(\d) S(\d) Z(\d) R(\d)/, proc{|m|
        self.video = m[1].to_i if m[1].to_i > 0
        self.audio = m[2].to_i if m[2].to_i > 0
        self.mute = (m[6] == "1")
      #self.clipping = (m[3] == "1")
    }
  end
  
  requests do
        send :video, "I", 0.5
        send :audio, "I", 0.5
  end
end
