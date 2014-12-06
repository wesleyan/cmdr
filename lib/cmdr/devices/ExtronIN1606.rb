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
# "name": "ExtronIN1606",
# "depends_on": "SocketVideoSwitcher",
# "description": "Controls the IN1606 Extron switcher",
# "author": "Brian Gapinski",
# "email": "bgapinski@wesleyan.edu",
# "abstract": true,
# "type": "Video Switcher"
#}
#---

class ExtronIN1606 < SocketVideoSwitcher
  
  managed_state_var :video,
    :type => :option,
    :display_order => 1,
    :options => ("1".."6").to_a,
    :response => :channel,
    :action => proc{|input|
      "#{input}!"
    }
  managed_state_var :volume,
    :type => :percentage,
    :display_order => 2,
    :response => :volume,
    :action => proc{|volume|
      volume >= 1 ? "\eD8*-1GRPM\r\n" : "\eD8*100#{volume > self.volume ? "+" : "-"}GRPM\r\n"
    }
  managed_state_var :mute,
    :type => :boolean,
    :display_order => 3,
    :response => :mute,
    :action => proc{|on|
      "\eD7*#{on ? 1 : 0}GRPM\r\n" 
    }
  
  state_var :model, :type => 'string', :editable => false
  state_var :firmware_version, :type => 'string', :editable => false
  state_var :part_number, :type => 'string', :editable => false
  state_var :clipping, :type => 'boolean', :display_order => 4, :editable => false
  
  responses do
    match :channel,  /Chn(\d)/, proc{|m| self.input = m[1].to_i.to_s}
    match :status,   /Vid(\d+) Aud(\d+)/, proc{|m|
      self.video = m[1].to_i if m[1].to_i > 0
      self.audio = m[2].to_i if m[2].to_i > 0
      #self.mute = (m[6] == "1")
      #self.clipping = (m[3] == "1")
    }
  match :info, /60-1081-01/, proc{|m|}
  match :volume, /-(\d+)/, proc{|m| 
    #DaemonKit.logger.info "Volume is at: #{(1000 - m[1].to_i) / 1000.0}"
    self.volume = (1000 - m[1].to_i) / 1000.0
  }
  match :mute, /(0|1)/, proc{|m|
        self.mute = (m[1].to_i == 1)
  }
  end
  
  requests do
    send :video, "I", 1
    send :volume, "\eD8GRPM\r\n", 0.05
    send :mute, "\eD7GRPM\r\n", 0.05
  end
end
