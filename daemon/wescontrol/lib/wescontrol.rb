require 'rubygems'
require 'couchrest'
require "#{File.dirname(__FILE__)}/MAC.rb"

require "#{File.dirname(__FILE__)}/wescontrol_http"
#if RUBY_PLATFORM[/linux/]
#	require "#{File.dirname(__FILE__)}/wescontrol_dbus"
#end
require "#{File.dirname(__FILE__)}/device"
require "#{File.dirname(__FILE__)}/RS232Device"
require "#{File.dirname(__FILE__)}/devices/Projector"
require "#{File.dirname(__FILE__)}/devices/VideoSwitcher"

Dir.glob("#{File.dirname(__FILE__)}/devices/*.rb").each{|device|
	begin
		require device
	rescue
		puts "Failed to load #{device}"
	rescue LoadError
		puts "Failed to load #{device}"
	end
}

module Wescontrol
	class Wescontrol
		def initialize(device_hashes)
			@db = CouchRest.database("http://localhost:5984/rooms")

			@devices = device_hashes.collect{|hash|
				begin
					Object.const_get(hash['value']['class']).from_couch(hash['value'])
				rescue
					puts "Failed to create device: #{$!}"
				end
			}.compact
			
			@method_table = {}
			@devices.each{|device|
				@method_table[device.name] = {:device => device, :methods => {}}
				device.state_vars.each{|name, options|
					@method_table[device.name][:methods][name] = options
					#this gives us the default behavior of editability
					if options['editable'] == nil || options['editable']
						@method_table[device.name]["set_#{name}"] = options
					end
				}
			}
			WescontrolHTTP.instance_variable_set(:@method_table, @method_table)
		end
			
		def inspect
			"<Wescontrol:0x#{object_id.to_s(16)}>"
		end
		
		def start		
			EventMachine::run {
				EventMachine.epoll
				EventMachine::start_server "0.0.0.0", 1412, WescontrolHTTP
				puts "Starting WescontrolHTTP on 0.0.0.0:1412"
				
				if defined? WescontrolDBus
					Thread.abort_on_exception = true
					Thread.new {
						WescontrolDBus.new(@devices).start
					}
				end
			}
		end
	end
end

require "#{File.dirname(__FILE__)}/wescontrol_room"
require "#{File.dirname(__FILE__)}/wescontrol_lab"