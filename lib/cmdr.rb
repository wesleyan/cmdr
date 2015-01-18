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
require 'couchrest'
require 'time'
require 'cmdr/constants'
require 'cmdr/device'
require 'cmdr/event_monitor'
require 'cmdr/cmdr_http'
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
    def initialize(device_hashes)
      credentials = Authenticate.get_credentials
      @credentials = "#{credentials[:user]}:#{credentials[:password]}"
      @db = CouchRest.database("http://#{@credentials}@localhost:5984/rooms")

      @devices = device_hashes.collect { |hash|
        begin
          device = Object.const_get(hash['value']['class']).from_couch(hash['value'])
        rescue
          err_msg = "Failed to create device #{hash['value']}: #{$ERROR_INFO}"
          DaemonKit.logger.error err_msg
        end
      }.compact
    end

    def inspect
      "<Cmdr:0x#{object_id.to_s(16)}>"
    end
    
    def start
      #start each device
      CmdrHTTP.instance_variable_set(:@devices, @devices.collect{|d| d.name})
      names_by_id = {}
      @devices.each{|d| names_by_id[d._id] = d.name}
      CmdrHTTP.instance_variable_set(:@device_ids, names_by_id)
      EventMachine::run {
        EventMachine::start_server "0.0.0.0", 1412, CmdrHTTP
        EventMonitor.run
        CmdrWebsocket.new.run
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
