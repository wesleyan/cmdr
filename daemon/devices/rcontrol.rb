require 'rubygems'
require 'dbus'
require 'dbus_fix'
require 'yaml'

require 'device'
require 'Projector'
require 'VideoSwitcher'

class RControl < DBus::Object
	@room_name
	def initialize(room_name)
		@room_name = room_name
		super("/edu/wesleyan/WesControl/controller")
	end
	
	dbus_interface "edu.wesleyan.WesControl.controller" do
		dbus_method :room_name, "out name:s" do
			[@room_name]
		end
	end
end

config = {}
begin
	config = YAML.load_file(ARGV[0])
	#TODO: actually check whether the config file is valid
rescue
	raise "Please pass a valid configuration file as an argument"
end

@devices = {}

bus          = DBus.session_bus
service      = bus.request_service("edu.wesleyan.WesControl")
rcontrol     = RControl.new(config['room_name'])
service.export(rcontrol)

config['devices'].each{|device|
	require device['class']
	device = Object.const_get(device['class']).new(device['name'], device['port'], bus)
	@devices[device.name] = device
	service.export(device)
}

begin
	main = DBus::Main.new
	main << bus
	main.run
rescue
	
end
