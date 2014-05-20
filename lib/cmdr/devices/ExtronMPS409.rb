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
# "name": "ExtronMPS409",
# "depends_on": "VideoSwitcher",
# "description": "Controls the MPS409 Extron switcher",
# "author": "Brian Gapinski",
# "email": "bgapinski@wesleyan.edu",
# "abstract": true,
# "type": "Video Switcher"
#}
#---

class ExtronMPS409 < VideoSwitcher
  AUDIO_HASH = {1 => "1*1", 2 => "1*2", 3 => "2*1", 4 => "2*2", 5 => "3*1", 6 => "3*2", 7 => "3*3", 8 => "4*1", 9 => "4*2"}

  def initialize(name, options)
    super(name, options)
  end

  managed_state_var :video,
    :type => :option,
    :display_order => 1,
    :options => ("1".."6").to_a,
    :response => :channel,
    :action => proc{|input|
      "#{input}!"
  }
  managed_state_var :audio,
    :type => :option,
    :display_order => 2,
    :options => ("1".."6").to_a,
    :response => :channel,
    :action => proc{|input|
      "#{AUDIO_HASH[input]}$"
  }

  responses do
    match :audio, /Mod(\d+) (\d)G(\d) (\d)G(\d) (\d)G(\d) (\d)G(\d)=(\d)G(\d)/, proc{|m|
      x1, x2 = [m[10].to_i, m[11].to_i]
      self.audio = "#{x1}*#{x2}"
    }
    match :video, /Mod(\d+) (\d)G(\d) (\d)G(\d) (\d)G(\d) (\d)G(\d)=(\d)G(\d)/, proc{|m|
      for i in (1..4)
        if m[2*i+1] != 0
          v1, v2 = [m[2*i].to_i, m[2*i+1].to_i]
          break
        end
      end
      self.video = (v1 < 3 ? ((v1-1)*2 + (v2-1) % 2 + 1) : ((v1-3)*3 + (v2-1) % 3 + 5))
    }
    end
end
