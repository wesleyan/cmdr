# Copyright (C) 2014 Wesleyan University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'rubygems'
require 'macaddr'
require 'couchrest'
require 'time'
require 'cmdr/constants'
require 'cmdr/device'
require 'cmdr/event_monitor'
require 'cmdr/RS232Device'
require 'cmdr/devices/Projector'
require 'cmdr/devices/VideoSwitcher'
require 'cmdr/devices/Computer'
require 'cmdr/process'
require 'cmdr/video-recorder'
require 'cmdr/video-encoder'
require 'cmdr/cmdr_websocket'
require 'cmdr/SocketDevice'
require 'cmdr/communication'
require 'cmdr/devices/SocketProjector'
require 'cmdr/authenticate'
require 'cmdr/devices/SocketBluray'
require 'cmdr/devices/ExtronVideoSwitcher'
require 'cmdr/devices/SocketVideoSwitcher'
require 'cmdr/devices/ExtronSystemPlus'
require 'cmdr/devices/SocketExtron'

Dir.glob("#{File.dirname(__FILE__)}/cmdr/devices/*.rb").each do |device|
  begin
    require device
  rescue => e
    DaemonKit.logger.error "Failed to load #{device}: #{$ERROR_INFO}"
    DaemonKit.logger.error e.backtrace
  rescue LoadError => e
    DaemonKit.logger.error "Failed to load #{device}: syntax error"
    DaemonKit.logger.error e.backtrace
  end
end

module Cmdr
  # The main cmdr module.
  class Cmdr
    # The main cmdr class.
    def initialize(device_hashes, main_server = nil)
      credentials = Authenticate.get_credentials
      @main_server = 'localhost'
      @main_server = main_server if main_server
      @credentials = "#{credentials[:user]}:#{credentials[:password]}"
      @db = CouchRest.database("http://#{@credentials}@#{main_server}:5984/rooms")
      @devices = device_hashes.collect { |hash|
        begin
          device = Object.const_get(hash['value']['class']).from_couch(hash['value'], main_server)
        rescue
          err_msg = "Failed to create device #{hash['value']}: #{$ERROR_INFO}"
          DaemonKit.logger.error err_msg
        end
      }.compact
    end

    def inspect
      "<Cmdr:0x#{object_id.to_s(16)}>"
    end
    
    def start(main_server=nil)
      #start each device
      names_by_id = {}
      @devices.each{|d| names_by_id[d._id] = d.name}
      EventMachine::run {
        EventMonitor.run unless main_server
        CmdrWebsocket.new.run unless main_server
        @devices.each{|device|
          Thread.new do
            begin
              device.run
            rescue
              DaemonKit.logger.error("Device #{device.name} failed: #{$!}")
              retry
            end
          end
        }
      }
    end
  end
end

require "#{File.dirname(__FILE__)}/cmdr/cmdr_room"
