require 'dbus'
module Wescontrol
	class WescontrolDBus < DBus::Object
		attr_accessor :wescontrol
		def initialize
			super("/edu/wesleyan/WesControl/controller")
			@bus = DBus::SystemBus.instance
			@service = @bus.request_service("edu.wesleyan.WesControl")
			@service.export(self)
			
			@devices.each{|device|
				@service.export(device)
			}
		end
		def start
			while true do
				#begin
					main = DBus::Main.new
					main << @bus
					main.run
				#rescue
				#	puts "Error: #{$!}"
				#end
			end
		end
		dbus_interface "edu.wesleyan.WesControl.controller" do
			dbus_method :room_name, "out name:s" do
				[self.name]
			end
		end
	end
end

@api = [
	#format:
	#[:message, 			[in], 			[out]] 
	[:set_power, 			["on:b"], 		["response:s"]],
	[:power, 				[], 			["on:b"]],
	[:set_video_mute, 		["on:b"], 		["response:s"]],
	[:video_mute, 			[], 			["on:b"]],
	[:set_input, 			["input:s"],	["response:s"]],
	[:set_brightness,		["input:u"],	["response:s"]],
	[:input, 				[], 			["input:s"]],
	[:cooling, 				[], 			["true:b"]],
	[:warming, 				[], 			["true:b"]],
	[:model, 				[], 			["model:s"]],
	[:lamp_hours, 			[], 			["hours:u"]],
	[:percent_lamp_used,	[], 			["percent:u"]]
]

dbus_interface "edu.wesleyan.WesControl.projector" do
	@api.each{|entry|
		entry[2] << "error:s" if entry[2].size == 0
		sig = (entry[1].collect{|s| "in #{s}"} + entry[2].collect{|s| "out #{s}"}).join(", ")
		dbus_method entry[0], sig do |*args|
			puts "Received command: #{args}"
			response = nil
			error = ""
			begin
				method = entry[0].to_s
				#method = "#{method.split("set_")[1]}=" if method.include?("set")
				response = self.__send__(method.to_sym, *args) #using the __send__ form because DBus::Object has its own send method
			rescue
				puts "ERROR: #{$!}"
				error = $!.to_s
			end
			responses = []
			if !response
				type_map = {"b" => false, "s" => "", "u" => 0}
				responses = [type_map[entry[2][0].split(":")[1]]]
				#responses = entry[2].collect{|s| type_map[s.split(":")[1]]}
			elsif response.class == Array
				responses = response
			else
				responses = [response]
			end
			puts "Response: #{responses.join(",")}"
			#responses.push(error)

			return responses #huh?
		end
	}
	dbus_signal :power_changed, "powered:b"
	dbus_signal :video_mute_changed, "on:b"
	dbus_signal :input_changed, "input:s"
	dbus_signal :cooling_changed, "on:b"
	dbus_signal :warming_changed,"on:b"
	dbus_signal :error, "message:s"
end
@api = [
	#format: 
	#message, 			[in], 			[out]

	[:set_volume, 		["volume:d"], 	["response:s"]],
	[:volume, 			[], 			["volume:d"]],
	[:set_mute, 		["on:b"], 		["response:s"]],
	[:mute,				[],				["on:b"]]
]
dbus_interface "edu.wesleyan.WesControl.volume" do
	@api.each{|entry|
		entry[2] << "error:s" if entry[2].size == 0
		sig = (entry[1].collect{|s| "in #{s}"} + entry[2].collect{|s| "out #{s}"}).join(", ")
		dbus_method entry[0], sig do |*args|
			puts "Received command: #{args}"
			response = nil
			error = ""
			begin
				method = entry[0].to_s
				#method = "#{method.split("set_")[1]}=" if method.include?("set")
				response = self.__send__(method.to_sym, *args) #using the __send__ form because DBus::Object has its own send method
			rescue
				puts "ERROR: #{$!}"
				error = $!.to_s
			end
			responses = []
			if !response
				type_map = {"b" => false, "s" => "", "u" => 0, "d" => 0}
				responses = [type_map[entry[2][0].split(":")[1]]]
				#responses = entry[2].collect{|s| type_map[s.split(":")[1]]}
			elsif response.class == Array
				responses = response
			else
				responses = [response]
			end
			puts "Response: #{responses.join(",")}"
			#responses.push(error)

			return responses #huh?
		end
	}
	
	dbus_signal :mute_changed, "on:b"
	dbus_signal :volume_changed, "volume:d"
end
