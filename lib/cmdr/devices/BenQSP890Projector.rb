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
# "name": "BenQSP890Projector",
# "depends_on": "Projector",
# "description": "Controls BenQ SP890 projector. Should also work with MP722, Mp723, MP771 and SP870",
# "author": "Micah Wylde",
# "email": "mwylde@wesleyan.edu"
#}
#---

class BenQSP890Projector < Projector  
  configure do
    message_end(/\n\r|\r\n/)
    message_delay 0.2
  end

  def read data
    EM.cancel_timer @_cooling_timer if @_cooling_timer
    @_cooling_timer = nil
    super data
  end

  managed_state_var :power, 
    :type => :boolean,
    :display_order => 1,
    :action => proc{|on|
      # The BenQs don't tell us when they're cooling, so we have to cheat
      if !@_cooling_timer && !on
        @_cooling_timer = EM.add_timer(5) { puts "Cooling..."; self.cooling = true }
      end
      "*pow=#{on ? "on" : "off"}#"
    }
  
  managed_state_var :input, 
    :type => :option,
    :options => ['HDMI', 'YPBR', 'RGB', 'RGB2', 'VID', 'SVID'],
    :display_order => 2,
    :action => proc{|source|
      "*sour=#{source.downcase}#"
    }

  managed_state_var :mute, 
    :type => :boolean,
    :action => proc{|on|
      "*mute=#{on ? "on" : "off"}#"
    }
  
  managed_state_var :video_mute,
    :type => :boolean,
    :display_order => 4,
    :action => proc{|on|
      "*blank=#{on ? "on" : "off"}#"
    }
    
  responses do
    ack /\*[a-z]+?=.+#/
    match :power,  /\*POW=(.+)#/, proc{|m|
      self.power = !(m[1].upcase == "OFF")
      self.cooling = (m[1].upcase == "COOL DOWN")
    }
    match :mute,       /\*MUTE=(.+)#/, proc{|m| self.mute = (m[1] == "ON")}
    match :video_mute, /\*BLANK=(.+)#/, proc{|m| self.video_mute = (m[1] == "ON")}
    match :input,      /\*SOUR=(.+)#/, proc{|m| self.input = m[1]}
  end
  
  requests do
    send :power, "*pow=?#", 1
    send :source, "*sour=?#", 1
    send :mute, "*blank=?#", 1
#    send :lamp_usage, "*ltim=?#", 0.1
  end
  
end
