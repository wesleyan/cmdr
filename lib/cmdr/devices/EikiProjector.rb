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
#	"name": "EpsonProjector",
#	"depends_on": "Projector",
#	"description": "Controls Epson PowerLite Pro G5750WU",
#	"author": "Micah Wylde",
#	"email": "mwylde@wesleyan.edu"
#}
#---

class EikiProjector < Projector  
  INPUT_HASH = {"RGB1" => 5, "RGB2" => 6, "VIDEO" => 7}

  configure do
    #DaemonKit.logger.info "@Initializing projector on port #{options[:uri]} with name #{name}"
    port :type => :port
    baud :type => :integer, :default => 19200
    data_bits 8
    stop_bits 1
    parity 0
  end

  managed_state_var :power, 
    :type => :boolean,
    :display_order => 1,
    :action => proc{|on|
       "C#{on ? "00" : "01"}\r"
	}
	
	managed_state_var :input, 
		:type => :option,
		# Numbers correspond to HDMI, YPBR, RGB, RGB2, VID, and SVID in that order
		:options => ['RGB1', 'RGB2', 'VIDEO', 'SVIDEO'] ,
		:display_order => 2,
		:action => proc{|source|
			"C0#{INPUT_HASH[source]}\r"
		}

	managed_state_var :video_mute,
		:type => :boolean,
		:display_order => 4,
		:action => proc{|on|
			"C#{on ? "0D" : "0E"}\r"
		}
		
	responses do
		ack "\x06"
		error :general_error, "", "Received an error"
		match :power,  /((0|2|4|8)0)/, proc{|m|
			#DaemonKit.logger.info "Received power value: #{m[1]}"
			if m[1] == "00"
				self.power = true
      elsif m[1] == "80"
        if self.power then self.video_mute = false end
        if self.cooling or not self.power
          self.power = false
        end
			#elsif self.power and m[1] == "80"
			#	self.video_mute = false
      #else
      #  self.power = false
			end

			self.cooling = (m[1] == "20")
      if m[1] == "40"
        self.warming = true
      elsif not m[1] == "80" and not m[1] == "40"
        self.warming = false
      end
		}
		match :video_mute, /(81)/, proc{|m| self.video_mute = true}
		match :input, /([1-3])/, proc{|m| 
			#DaemonKit.logger.debug "Recieved source value: #{m[1]}"
			if m[1] == "1"
				self.input = "RGB1"
			elsif m[1] == "2"
				self.input = "RGB2"
			else
				self.input = "VIDEO"
			end 
		}
	end
	
	requests do
           send :power, "CR0\r", 1
           send :source, "CR1\r", 1
           send :mute, "CRA\r", 1
	   send :clear, "\n", 1
           #send :lamp_usage, "CR3\r", 0.1
	end

  
end
