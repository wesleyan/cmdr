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
# "name": "SocketBluray",
# "depends_on": "SocketDevice",
# "description": "Controls most pioneer bluray players",
# "author": "Brian Gapinski",
# "email": "bgapinski@wesleyan.edu",
# "type": "SocketDevice"
#}
#---

class SocketBluray < Cmdr::SocketDevice

#  configure do
    #DaemonKit.logger.info "@Initializing SocketBluray at URI #{options[:uri]} with name #{name}"
#  end

  command :play, 
      :action => proc{
      send_string "PL\r\n"
  }
  command :stop,
    :action => proc{
      send_string "99RJ\r\n"
    }
  command :pause,
    :action => proc{
      send_string "ST\r\n"
    }
  command :forward,
    :action => proc{
      send_string "NF\r\n"
    }
  command :back,
    :action => proc{
      send_string "NR\r\n"
    }
  command :next,
    :action => proc{
      #send_string "SF\r\n"
      send_string "/A181AF3D/RU\r\n"
    }
  command :previous,
    :action => proc{
      #send_string "SR\r\n"
      send_string "/A181AF3E/RU\r\n"
    }
  command :title,
    :action => proc{
      send_string "/A181AFB9/RU\r\n"
    }
  command :menu,
    :action => proc{
      send_string "/A181AFB4/RU\r\n"
    }
  command :up,
    :action => proc{
      send_string "/A184FFFF/RU\r\n"
    }
  command :right,
    :action => proc{
      send_string "/A186FFFF/RU\r\n"
    }
  command :down,
    :action => proc{
      send_string "/A185FFFF/RU\r\n"
    }
  command :left,
    :action => proc{
      send_string "/A187FFFF/RU\r\n"
    }
  command :enter,
    :action => proc{
      send_string "/A181AFEF/RU\r\n"
    }
  command :eject,
    :action => proc{
      send_string "/A181AFB6/RU\r\n"
    }


  state_var :operational, :type => :boolean, :editable => false

  requests do
    send :ping, "\r\n", 1.0
    send :time, "?T\r\n", 0.1
  end

end
