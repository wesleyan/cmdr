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
#	"name": "PJLinkProjector",
#	"depends_on": "SocketProjector",
#	"description": "Controls any projector capable of understanding the PJLink protocol standard, ie. the Epson PowerLite Pro G5750WU",
#	"author": "Jonathan Lyons",
#	"email": "jclyons@wesleyan.edu",
# "type": "Projector"
#}
#---
require 'digest/md5'

class PJLinkProjector < SocketProjector  
  INPUT_HASH = {"HDMI" => 32, "YPBR" => 13, "RGB1" => 11, "VIDEO" => 23, "SVIDEO" => 22}
  ERROR = ["Fan", "Lamp", "Temperature", "Cover open", "Filter", "Other"]

  configure do
    #DaemonKit.logger.info "@Initializing PJLinkProjector at URI #{options[:uri]} with name #{@name}"
  end

  def initialize(name, options)
    options = options.symbolize_keys
    @_password = options[:password]
    super(name, options)
  end

  # Generates the auth key for pjlink
  def read data
    EM.cancel_timer @_cooling_timer if @_cooling_timer
    @_cooling_timer = nil
    if data.start_with? "PJLINK 1"
      @_digest = Digest::MD5.hexdigest "#{data.chop[9..-1]}#{@_password}"
    end
    super data 
  end

  def send_string(string)
    string = @_digest+string if @_digest
    super string
  end

  def interpret_error(error)
    DaemonKit.logger.info "Projector has error code: #{error}"
    (1..6).each do |i|
      e = error[i]
      if e == "1"
        register_error @name, "WARNING: #{ERROR[i]}", 0.5
      elsif e == "2"
        register_error @name, "ERROR: #{ERROR[i]}", 0.9
      end
    end
  end

  def change_power(state)
    if state and not self.power
        self.power = true
        start_shutdown_timers
    else
      self.power = false
      cancel_shutdown_timers
    end
  end

  def timer val
    cancel_shutdown_timers unless val
  end

  def start_shutdown_timers
    @warning_timer = EventMachine::Timer.new(30) do
      @shutoff_timer = EventMachine::Timer.new(30) do
        send_string "%1POWR 0"
      end
    end
    self.timer = true
  end

  def cancel_shutdown_timers
    @warning_timer.cancel if @warning_timer
    @shutoff_timer.cancel if @shutoff_timer
    self.timer = false
  end

	managed_state_var :power, 
		:type => :boolean,
		:display_order => 1,
		:action => proc{|on|
      "%1POWR #{on ? "1" : "0"}\r"
		}

	managed_state_var :input, 
		:type => :option,
		# Numbers correspond to HDMI, YPBR, RGB, RGB2, VID, and SVID in that order
		:options => [ 'HDMI', 'YPBR', 'RGB1', 'VID', 'SVID'],
		:display_order => 2,
		:action => proc{|source|
			"%1INPT #{INPUT_HASH[source]}\r"
		}

	managed_state_var :mute, 
		:type => :boolean,
		:action => proc{|on|
			"%1AVMT #{on ? "31" : "30"}\r"
		}

	managed_state_var :video_mute,
		:type => :boolean,
		:display_order => 4,
		:action => proc{|on|
			"%1AVMT #{on ? "31" : "30"}\r"
		}

  managed_state_var :timer, 
    :type => :boolean,
    :display_order => 5,
    :action => proc{|val|
      timer val
    }

	responses do
		#ack ":"
		error :general_error, "ERR", "Received an error"
    match :err_status, /%1ERST=(\d+)/, proc{|m|
        interpret_error m[1] if m[1] != "000000"
    }
		match :power,  /%1POWR=(.+)/, proc{|m|
			  change_power(m[1] == "1") 
	  		self.cooling = (m[1] == "2")
	  		self.warming = (m[1] == "3") || (m[1] == "ERR3")
		}
		match :video_mute, /%1AVMT=(.+)/, proc{|m| self.video_mute = (m[1] == "31")}
		match :input,      /%1INPT=(.+)/, proc{|m| self.input = m[1]}
    match :lamp_hours, /%1LAMP=(\d+) (\d)/, proc {|m|
        self.lamp_hours = m[1].to_i
        self.percent_lamp_used =((m[1].to_f / 2000) * 100).floor
    }
    match :name, /%1NAME=(.*)/, proc{|m|
        self.projector_name = m[1].chomp 
    }

	end

	requests do
           send :power, "#{@_digest}%1POWR ?\r", 1
           send :source, "#{@_digest}%1INPT ?\r", 1
           send :mute, "#{@_digest}%1AVMT ?\r", 1
           send :err_status, "#{@_digest}%1ERST ?\r", 0.1
           send :lamp_usage, "#{@_digest}%1LAMP ?\r", 0.1
           send :info, "#{@_digest}%1NAME ?\r", 0.01
	end

end
