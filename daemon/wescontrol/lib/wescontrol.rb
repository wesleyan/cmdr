#!/usr/bin/env ruby
require 'rubygems'
require 'dbus'
require 'yaml'
require 'drb/drb'
require 'macaddr'

require 'bitpack'
require 'couch_object'

require "#{File.dirname(__FILE__)}/device"
require "#{File.dirname(__FILE__)}/RS232Device"
require "#{File.dirname(__FILE__)}/devices/Projector"
require "#{File.dirname(__FILE__)}/devices/VideoSwitcher"


#URI = "druby://localhost:8787"
module WesControl
	class WesControl < DBus::Object
		def initialize
			super("/edu/wesleyan/WesControl/controller")
			@db = CouchObject::Database.open("http://localhost:5984/rooms")
			begin
				@config = @db.get(Mac.addr)
			rescue
				raise "The room has not been added the database"
			end

			@devices = {}

			bus          = DBus::SystemBus.instance
			service      = bus.request_service("edu.wesleyan.WesControl")
			rcontrol     = RControl.new(room_name)
			service.export(rcontrol)

			@config['devices'].each{|device|
				require "#{File.dirname(__FILE__)}/devices/#{device['class']}"
				device = Object.const_get(device['class']).new(device['name'], bus, device)					
				@devices[device.name] = device
				service.export(device)
			}

			#FRONT_OBJECT = @devices
			#$SAFE = 1 # disable eval() and friends
		
		end
	
		def start
			#DRb.start_service(URI, FRONT_OBJECT)

			while(true) do
				#begin
					main = DBus::Main.new
					main << bus
					main.run
				#rescue
				#	puts "Error: #{$!}"
				#end
			end
		end
	
		dbus_interface "edu.wesleyan.WesControl.controller" do
			dbus_method :room_name, "out name:s" do
				[@config['name']]
			end
		end
	end
	
	class Building
		include CouchObject::Persistable
		database "http://localhost:5984/rooms"
		attr_accessor :name
		has_many :rooms
	end

	class Room
		include CouchObject::Persistable
		database "http://localhost:5984/rooms"
		attr_accessor :name, :log_db
		belongs_to :building, :as => :rooms
		has_many :devices
	end
end
