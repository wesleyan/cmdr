require 'rubygems'
require 'dbus'
require 'dbus_fix'

class Device < DBus::Object
	attr_reader :name
	attr_writer :name
	
	protected
	def initialize(name,  bus)
		@name = name
		super("/edu/wesleyan/WesControl/#{name}")
		#main = DBus::Main.new
		#main << bus
		#main.run
	end
end
