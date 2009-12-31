#require "#{File.dirname(__FILE__)}/wescontrol/RS232Device"

class VideoSwitcher < RS232Device

	state_var :input, :kind => 'number'
	state_var :volume, :kind => 'percentage'
	state_var :mute, :kind => 'boolean'
	
	def initialize(port, baud_rate, data_bits, stop_bits, name, bus)
		super(port, baud_rate, data_bits, stop_bits, name, bus)	
	end
	
	@api = [
		#format: 
		#message, 			[in], 			[out]
		[:set_input, 		["number:u"],	["response:s"]],
		[:input, 			[], 			["number:u"]],
		[:set_volume, 		["volume:d"], 	["response:s"]],
		[:volume, 			[], 			["volume:d"]],
		[:set_mute, 		["on:b"], 		["response:s"]],
		[:mute,				[],				["on:b"]]
	]
	
	dbus_interface "edu.wesleyan.WesControl.videoSwitcher" do
		@api.each{|entry|
			entry[2] << "error:s" if entry[2].size == 0
			sig = (entry[1].collect{|s| "in #{s}"} + entry[2].collect{|s| "out #{s}"}).join(", ")
			dbus_method entry[0], sig do |*args|
				puts "Received command: #{args}"
				response = nil
				error = ""
				begin
					method = entry[0].to_s
					method = "#{method.split("set_")[1]}=" if method.include?("set")
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
		
		dbus_signal :input_changed, "input:u"
		dbus_signal :mute_changed, "on:b"
		dbus_signal :volume_changed, "volume:d"
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
					method = "#{method.split("set_")[1]}=" if method.include?("set")
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
		
		dbus_signal :mute_changed, "on:b"
		dbus_signal :volume_changed, "volume:d"
	end
#	dbus_interface "edu.wesleyan.WesControl.volume" do
#		dbus_method :volume, "out volume:d" do
#			return [self.volume]
#		end
#		dbus_method :set_volume, "in volume:d, out response:s" do
#			response = (self.volume = volume)
#			return [response]
#		end
#		dbus_method :mute, "out on:b" do
#			return [self.mute]
#		end
#		dbus_method :set_mute, "in on:b, out response:s" do
#			response = (self.mute = on)
#			return [response]
#		end
#		dbus_signal :volume_changed, "volume:d"
#		dbus_signal :mute_changed, "on:b"
#	end
end
