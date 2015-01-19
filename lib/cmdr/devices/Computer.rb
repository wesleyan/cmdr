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
# "name": "Computer",
# "depends_on": "Device",
# "description": "A generic computer class, providing reachability monitoring",
# "author": "Micah Wylde",
# "email": "mwylde@wesleyan.edu",
# "type": "Computer"
#}
#---

require 'wol'

require 'timeout'
require "socket"

module Ping
  def pingecho(host, timeout=5, service="echo")
    begin
      timeout(timeout) do
        s = TCPSocket.new(host, service)
        s.close
      end
    rescue Errno::ECONNREFUSED
      return true
    rescue Timeout::Error, StandardError
      return false
    end
    return true
  end
  module_function :pingecho
end


class Computer < Cmdr::Device
  #attempt to turn on the computer via WoL
  command :start, :action => proc{
    w = Wol::WakeOnLan.new(:address => configuration[:ip_address], :mac => self.mac_address)
    w.wake
  }
  
  #current info
  state_var :reachable, :type => :boolean, :editable => false, :display_order => 1
  
  def initialize(name, options)
  configure do
    ip_address :type => :string
    mac_address :type => :string
  end
    @ip_address = options[:ip_address]
    super(name, options)
    
    EM.defer {
      Thread.abort_on_exception = true
      while true
        @reachable = Ping.pingecho(configuration[:ip_address])
        sleep 5
      end
    }
  end 
end

#126.184
