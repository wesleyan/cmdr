require 'rubygems'
require 'macaddr'
require 'couchrest'

require "#{File.dirname(__FILE__)}/wescontrol_http"
if RUBY_PLATFORM[/linux/]
	require "#{File.dirname(__FILE__)}/wescontrol_dbus"
end
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
		def initialize
			@db = CouchRest.database("http://localhost:5984/rooms")
			begin
				@room = Room.find_by_mac(Mac.addr)
				throw "Room Does Not Exist" unless @room
			rescue
				raise "The room has not been added the database"
			end

			puts "Ready to start finding devices"
			device_hashes = Room.devices(@room["id"])
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
			
		def self.define_db_views(db_uri)
			db = CouchRest.database(db_uri)

			doc = {
				"_id" => "_design/wescontrol",
				:views => {
					:by_mac => {
						:map => "function(doc) {
							if(doc.attributes && doc.attributes[\"mac\"]){
								emit(doc.attributes[\"mac\"], doc);
							}
						}".gsub(/\s/, "")
					},
					:devices_for_room => {
						:map => "function(doc) {
							if(doc.belongs_to)
							{
								emit(doc.belongs_to, doc);
							}
						}".gsub(/\s/, "")
					}
				}
			}
			begin 
				doc["_rev"] = db.get("_design/wescontrol").rev
			rescue
			end
			db.save_doc(doc)
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

	class Room
		@database = "http://localhost:5984/rooms"
		
		def self.find_by_mac(mac, db_uri = @database)
			db = CouchRest.database(db_uri)
			retried = false
			begin
				db.get("_design/wescontrol").view("by_mac", {:key => mac})['rows'][0]
			rescue RestClient::ResourceNotFound
				Wescontrol.define_db_views(db_uri)
				if !retried #prevents infinite retry loop
					retried = true
					retry
				end
				nil
			rescue
				nil
			end
		end
		
		def self.devices(room, db_uri = @database)
			db = CouchRest.database(db_uri)
			retried = false
			begin
				db.get("_design/wescontrol").view("devices_for_room", {:key => room})['rows']
			rescue RestClient::ResourceNotFound
				Wescontrol.define_db_views(db_uri)
				if !retried #prevents infinite retry loop
					retried = true
					retry
				end
				nil
			rescue
				nil
			end
		end
	end
end
