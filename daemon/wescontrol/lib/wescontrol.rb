#!/usr/bin/env ruby
require 'rubygems'
require 'dbus'
require 'yaml'
require 'drb/drb'
require 'macaddr'

require 'bitpack'
require 'couchrest'

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




#URI = "druby://localhost:8787"
module Wescontrol
	class Wescontrol < DBus::Object
		def initialize
			super("/edu/wesleyan/WesControl/controller")
			@db = CouchRest.database("http://localhost:5984/rooms")
			begin
				@room = Room.find_by_mac(Mac.addr)
				throw "Room Does Not Exist" unless @room
			rescue
				raise "The room has not been added the database"
			end

			@bus = DBus::SystemBus.instance
			@service = @bus.service("edu.wesleyan.WesControl")
			@service.export(self)
			puts "Ready to start finding devices"
			device_hashes = Room.devices(@room["id"])
			@devices = device_hashes.collect{|hash|
				#begin
					Object.const_get(hash['value']['class']).from_couch(hash['value'])
				#rescue
				#	puts "Failed to create device: #{$!}"
				#end
			}.compact
			puts "Devices: #{@devices.inspect}"
			@devices.each{|device|
				#require "#{File.dirname(__FILE__)}/devices/#{device['class']}"
				#device = Object.const_get(device['class']).new(device['name'], bus, device)					
				#@devices[device.name] = device
				@service.export(device)
			}

			#FRONT_OBJECT = @devices
			#$SAFE = 1 # disable eval() and friends
		
		end
	
		def start
			#DRb.start_service(URI, FRONT_OBJECT)

			while(true) do
				#begin
					main = DBus::Main.new
					main << @bus
					main.run
				#rescue
				#	puts "Error: #{$!}"
				#end
			end
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
	
		dbus_interface "edu.wesleyan.WesControl.controller" do
			dbus_method :room_name, "out name:s" do
				[self.name]
			end
		end
		
		def inspect
			"<WesControl>"
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
