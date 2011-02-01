libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'rubygems'
require 'couchrest'
require 'time'
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

Dir.glob("#{File.dirname(__FILE__)}/roomtrol/devices/*.rb").each{|device|
	begin
		require device
	rescue => e
		DaemonKit.logger.exception e # "Failed to load #{device}: #{$!}"
	rescue LoadError
		DaemonKit.logger.error "Failed to load #{device}: syntax error"
	end
}

module Wescontrol
	class Wescontrol
		def initialize(device_hashes)
			@db = CouchRest.database("http://localhost:5984/rooms")

			@devices = device_hashes.collect{|hash|
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
			WescontrolHTTP.instance_variable_set(:@devices, @devices.collect{|d| d.name})
			EventMachine::run {
				EventMachine::start_server "0.0.0.0", 1412, WescontrolHTTP
				EventMonitor.run
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

require "#{File.dirname(__FILE__)}/roomtrol/wescontrol_room"
require "#{File.dirname(__FILE__)}/roomtrol/wescontrol_lab"
