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
# "name": "VideoSwitcher",
# "depends_on": "RS232Device",
# "description": "Generic class for videoswitchers.",
# "author": "Micah Wylde",
# "email": "mwylde@wesleyan.edu",
# "abstract": true,
# "type": "Video Switcher"
#}
#---

class VideoSwitcher < Cmdr::RS232Device
  state_var :input, :type => :option, :display_order => 1, :options => ("1".."6").to_a
  state_var :volume, :type => :percentage, :display_order => 2
  state_var :mute, :type => :boolean, :display_order => 3
  state_var :operational, :type => :boolean
end
