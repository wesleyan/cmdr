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
#	"name": "Printer",
#	"depends_on": "Computer",
#	"description": "Generic class for printer monitoring.",
#	"author": "Micah Wylde",
#	"email": "mwylde@wesleyan.edu",
#	"abstract": true,
#	"type": "Printer"
#}
#---

class Printer < Computer

	configure do
		ip_address :type => :string
	end
	
	#current info
	state_var :pages_remaining,     :type => :integer,  :editable => false
	state_var :toner_low,           :type => :boolean,  :editable => false
	state_var :toner_out,           :type => :boolean,  :editable => false
	state_var :paper_out,           :type => :boolean,  :editable => false
	state_var :toner_remaining,     :type => :percentage, :editable => false
	state_var :jammed,              :type => :boolean,  :editable => false
	state_var :page_count,          :type => :integer,  :editable => false
	
	#other
	state_var :model,               :type => :string,   :editable => false
	state_var :serial_number,       :type => :string,   :editable => false
	state_var :memory,              :type => :integer,  :eidtable => false
	
	def initialize(options)
		super(options)
	end
	
end
