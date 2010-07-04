require 'rubygems'
require 'couchrest'
require 'time'
require "#{File.dirname(__FILE__)}/roomtrol/device"
require "#{File.dirname(__FILE__)}/roomtrol/wescontrol_http"
require "#{File.dirname(__FILE__)}/roomtrol/RS232Device"
require "#{File.dirname(__FILE__)}/roomtrol/devices/Projector"
require "#{File.dirname(__FILE__)}/roomtrol/devices/VideoSwitcher"
require "#{File.dirname(__FILE__)}/roomtrol/devices/Computer"
require "#{File.dirname(__FILE__)}/roomtrol/MAC.rb"

Dir.glob("#{File.dirname(__FILE__)}/roomtrol/devices/*.rb").each{|device|
	begin
		require device
	rescue
		DaemonKit.logger.error "Failed to load #{device}: #{$!}"
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
					Thread.new {
						begin
							device.run
						rescue
							DaemonKit.logger.error("Device #{device.name} failed: #{$!}")
							retry
						end
					}
					device
				rescue
					DaemonKit.logger.error "Failed to create device: #{$!}"
				end
			}.compact
			
			#WescontrolHTTP.instance_variable_set(:@couchid, @couchid)
			#WescontrolHTTP.instance_variable_set(:@controller, @controller)
		end
			
		def inspect
			"<Wescontrol:0x#{object_id.to_s(16)}>"
		end
		
		def start
			WescontrolHTTP.instance_variable_set(:@devices, ["extron"])
			EventMachine::run {
				EventMachine::start_server "0.0.0.0", 1412, WescontrolHTTP
			}
		end
	end
end

require "#{File.dirname(__FILE__)}/roomtrol/wescontrol_room"
require "#{File.dirname(__FILE__)}/roomtrol/wescontrol_lab"