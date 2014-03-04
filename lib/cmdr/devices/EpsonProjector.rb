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
#	"email": "mwylde@wesleyan.edu",
# "type": "Projector"
#}
#---

class EpsonProjector < Projector  
  INPUT_HASH = {"HDMI" => 30, "YPBR" => 14, "RGB1" =>  11, "VIDEO" => 41, "SVIDEO" => 42}

  configure do
    #DaemonKit.logger.info "@Initializing projector on port #{options[:port]} with name #{name}"
    port :type => :port
    baud :type => :integer, :default => 9600
    data_bits 8
    stop_bits 1
    parity 0
    message_end "\r:"
    message_timeout 2.0
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
      if !@_cooling_timer && !on
        @_cooling_timer = EM.add_timer(5) { puts "Cooling..."; self.cooling = true }
      end

      "PWR #{on ? "ON" : "OFF"}\r\r"
		}
	
	managed_state_var :input, 
		:type => :option,
		# Numbers correspond to HDMI, YPBR, RGB, RGB2, VID, and SVID in that order
		:options => [ 'HDMI', 'YPBR', 'RGB1', 'VID', 'SVID'],
		:display_order => 2,
		:action => proc{|source|
			"SOURCE #{INPUT_HASH[source]}\r"
		}

	managed_state_var :mute, 
		:type => :boolean,
		:action => proc{|on|
			"MUTE #{on ? "ON" : "OFF"}\r"
		}
	
	managed_state_var :video_mute,
		:type => :boolean,
		:display_order => 4,
		:action => proc{|on|
			"MUTE #{on ? "ON" : "OFF"}\r"
		}
		
	responses do
		ack ":"
		error :general_error, "ERR", "Received an error"
		match :power,  /PWR=(.+)/, proc{|m|
	  		#DaemonKit.logger.info "Received power value #{m[1]}"
			self.power = (m[1] == "01")
			self.cooling = (m[1] == "03")
			self.warming = (m[1] == "02")	
		}
	#	match :mute,       /MUTE=(.+)/, proc{|m| self.mute = (m[1] == "OFF")}
		match :video_mute, /MUTE=(.+)/, proc{|m| self.video_mute = (m[1] == "ON")}
		match :input,      /SOURCE=(.+)/, proc{|m| self.input = m[1]}
	end
	
	requests do
           send :power, "PWR?\r", 1
           send :source, "SOURCE?\r", 1
           send :mute, "MUTE?\r", 1
           send :lamp_usage, "*ltim=?#", 0.1
	end

  
end
