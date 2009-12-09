require 'rubygems'
require 'dbus'
require 'couch_object'

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

class Device < DBus::Object
	include CouchObject::Persistable
	database "http://localhost:5984/rooms"
	attr_accessor :name, :module
	
	belongs_to :room, :as => :devices
	
	protected
	def initialize(name,  bus)
		@name = name
		super("/edu/wesleyan/WesControl/#{name}")
		#main = DBus::Main.new
		#main << bus
		#main.run
	end
	
	def state_vars (*syms)
		syms.each do |sym|
			@state_vars += sym unless @state_vars.include? sym
			class_eval %{
				def #{sym}= (val)
					@#{sym} = val
					self.save
				end
			}
		end
	end
	
	def to_couch
		hash = {
			
			'state' => nil
		}
		@state_vars.each{|var|
			hash['state'][var] = self.send(var)
		}
		return hash
	end
end
