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
#	"name": "Camera",
#	"inherits": "RS232Device",
#	"description": "The base class for all camera devices; never instantiated",
#	"author": "Micah Wylde",
#	"email": "mwylde@wesleyan.edu",
#	"abstract": true,
#	"type": "Camera"
#}
#---

class Camera < Cmdr::RS232Device
	
	state_var :power, 		:type => :boolean, :display_order => 1
	state_var :video_mute, 	:type => :boolean, :display_order => 4
	state_var :input, 		:type => :option, :options => ['RGB1','RGB2','VIDEO','SVIDEO'], :display_order => 2
	state_var :brightness,	:type => :percentage, :display_order => 3
	state_var :cooling,		:type => :boolean, :editable => false
	state_var :warming,		:type => :boolean, :editable => false
	state_var :model,		:type => :string, :editable => false
	state_var :lamp_hours,	:type => :number, :editable => false
	state_var :filter_hours,:type => :number, :editable => false
	state_var :percent_lamp_used, :type => :percentage, :editable => false

end
