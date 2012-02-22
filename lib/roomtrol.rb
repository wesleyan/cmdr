libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'rubygems'
require 'couchrest'
require 'time'
require 'em-zeromq'
require 'tempfile'
require 'digest/md5'
require 'roomtrol/constants'
require 'roomtrol/device'
require 'roomtrol/event_monitor'
require 'roomtrol/wescontrol_http'
require 'roomtrol/RS232Device'
require 'roomtrol/devices/Projector'
require 'roomtrol/devices/VideoSwitcher'
require 'roomtrol/devices/Computer'
require 'roomtrol/MAC.rb'
require 'roomtrol/process'
require 'roomtrol/video-recorder'
require 'roomtrol/video-encoder'
require 'roomtrol/wescontrol_websocket'
require 'roomtrol/zmqclient'

Dir.glob("#{File.dirname(__FILE__)}/roomtrol/devices/*.rb").each{|device|
	begin
		require device
	rescue => e
		DaemonKit.logger.error "Failed to load #{device}: #{$!}"
		DaemonKit.logger.error e.backtrace
	rescue LoadError => error
		DaemonKit.logger.error "Failed to load #{device}: syntax error"
		DaemonKit.logger.error e.backtrace
	end
}

module Wescontrol
	class Wescontrol
		def initialize(device_hashes)
			@db = CouchRest.database("http://localhost:5984/rooms")

			@devices = device_hashes.collect{|[hash|
				begin
					device = Object.const_get(hash['value']['class']).from_couch(hash['value'])
				rescue
					DaemonKit.logger.error "Failed to create device #{hash['value']}: #{$!}"
				end
			}.compact
		end

		def inspect
			"<Wescontrol:0x#{object_id.to_s(16)}>"
		end

		def start
			#start each device
			EventMachine::run {
				# EventMonitor.run
        device_paths = {}
				@devices.each{|device|
          file = "ipc:///tmp/roomtrol-device-#{Digest::MD5.hexdigest(device._id)}"
          device_paths[device._id] = device
					Thread.new do
						begin
							device.run file
						rescue
							DaemonKit.logger.error("Device #{device.name} failed: #{$!}")
							retry
						end
					end
				}

        # Start the websocket server
        RoomtrolWebsocket.instance_variable_set(:@device_paths, device_paths)
        RoomtrolWebsocket.new.run rescue nil
        # and HTTP server
        WescontrolHTTP.instance_variable_set(:@device_paths, device_paths)
				EventMachine::start_server "0.0.0.0", 1412, WescontrolHTTP
			}
		end
	end
end

require "#{File.dirname(__FILE__)}/roomtrol/wescontrol_room"
require "#{File.dirname(__FILE__)}/roomtrol/wescontrol_lab"
