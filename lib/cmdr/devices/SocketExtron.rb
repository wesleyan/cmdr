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
# "name": "ExtronVideoSwitcher",
# "depends_on": "VideoSwitcher",
# "description": "Controls Extron video switchers that support SIS",
# "author": "Micah Wylde",
# "email": "mwylde@wesleyan.edu"
#}
#---

class SocketExtron < SocketVideoSwitcher
  configure do
    #DaemonKit.logger.info "@Initializing SocketExtron at URI #{options[:uri]} with name #{name}"
    message_end "\r\n"
  end
  #managed_state_var :input, 
  # :type => :option, 
  # :display_order => 1, 
  # :options => ("1".."6").to_a,
  # :response => :channel,
  # :action => proc{|input|
  #   "#{input}!"
  # }
  managed_state_var :video,
    :type => :option,
    :display_order => 1,
    :options => ("1".."6").to_a,
    :response => :channel,
    :action => proc{|input|
      "q#{input}!"
    }
  managed_state_var :audio,
    :type => :option,
    :display_order => 2,
    :options => ("1".."6").to_a,
    :response => :channel,
    :action => proc{|input|
      "q#{input}$"
    }
  managed_state_var :volume,
    :type => :percentage,
    :display_order => 3,
    :response => :volume,
    :action => proc{|volume|
      "q#{(volume*100).to_i}V"
    }
  managed_state_var :mute,
    :type => :boolean,
    :display_order => 4,
    :response => :mute,
    :action => proc{|on|
      on ? "q1Z" : "q0Z"
    }
  
  state_var :model, :type => 'string', :editable => false
  state_var :firmware_version, :type => 'string', :editable => false
  state_var :part_number, :type => 'string', :editable => false
  state_var :clipping, :type => 'boolean', :display_order => 5, :editable => false
  
  responses do
    match :channel,  /Chn(\d)/, proc{|m| self.video = m[1].to_i.to_s}
    match :volume,   /Vol(\d+)/, proc{|m| self.volume = m[1].to_i/100.0}
    match :mute,     /Amt(\d+)/, proc{|m| self.mute = m[1] == "1"}
    match :status,   /Vid(\d+) Aud(\d+) Clp(\d)/, proc{|m|
      #self.input = m[1].to_i if m[1].to_i > 0
      self.video = m[1].to_i if m[1].to_i > 0
      self.audio = m[2].to_i if m[2].to_i > 0
      self.clipping = (m[3] == "1")
    }
    match :audio, /Mod(\d+) (\d)G(\d) (\d)G(\d) (\d)G(\d) (\d)G(\d)=(\d)G(\d)/, proc{|m|
      x1, x2 = [m[10].to_i, m[11].to_i]
    #DaemonKit.logger.debug("INPUT = (#{i}, #{x1}, #{x2})")
      self.audio = "#{x1}*#{x2}"
    } 
    match :video, /Mod(\d+) (\d)G(\d) (\d)G(\d) (\d)G(\d) (\d)G(\d)=(\d)G(\d)/, proc{|m|
      for i in (1..4)
        if m[2*i+1] != 0
          v1, v2 = [m[2*i].to_i, m[2*i+1].to_i]
          break
        end
      end
      self.video = (v1 < 3 ? ((v1-1)*2 + (v2-1) % 2 + 1) : ((v1-3)*3 + (v2-1) % 3 + 5)) if (v1 && v2)
      #DaemonKit.logger.info "Received video input #{v1} and #{v2}"
    }
    end
  
  requests do
    #send :input, "I", 0.5
    send :video, "I", 0.5
    send :audio, "I", 0.5
    send :volume, "V", 0.5
    send :mute, "Z", 0.5
  end
end
