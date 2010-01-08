require '/usr/local/wescontrol/daemon/devices/device'

class PowerPoint < Device

	def initialize(name, bus)
		super(name, bus)	
	end
	
	@api = [
		#format:
		#[:message, 			[in], 			[out]] 
		[:open_ppt, 			["file:s"], 	["response:s"]],
		[:launch_program, 		[], 			["response:s"]],
		[:start_show, 			[], 			["response:s"]],
		[:end_show,				[],				["response:s"]],
		[:get_slides_as_png, 	[], 			[""]],
		[:go_to_slide, 			["input:u"],	["response:s"]],
		[:next_slide,			[],				["response:s"]],
		[:previous_slide, 		[], 			["response:s"]],
		[:current_slide, 		[], 			["number:u"]],
		[:current_notes, 		[], 			["true:b"]]
	]
	
#	dbus_interface "edu.wesleyan.WesControl.powerpoint" do
#		@api.each{|entry|
#			entry[2] << "error:s" if entry[2].size == 0
#			sig = (entry[1].collect{|s| "in #{s}"} + entry[2].collect{|s| "out #{s}"}).join(", ")
#			dbus_method entry[0], sig do |*args|
#				puts "Received command: #{args}"
#				response = nil
#				error = ""
#				begin
#					method = entry[0].to_s
#					method = "#{method.split("set_")[1]}=" if method.include?("set")
#					response = self.__send__(method.to_sym, *args) #using the __send__ form because DBus::Object has its own send method
#				rescue
#					puts "ERROR: #{$!}"
#					error = $!.to_s
#				end
#				responses = []
#				if !response
#					type_map = {"b" => false, "s" => "", "u" => 0}
#					responses = [type_map[entry[2][0].split(":")[1]]]
#					#responses = entry[2].collect{|s| type_map[s.split(":")[1]]}
#				elsif response.class == Array
#					responses = response
#				else
#					responses = [response]
#				end
#				puts "Response: #{responses.join(",")}"
#				#responses.push(error)
#
#				return responses #huh?
#			end
#		}
#		dbus_signal :powerpoint_launched, ""
#		dbus_signal :powerpoint_closed, ""
#		dbus_signal :slideshow_started, ""
#		dbus_signal :slideshow_ended, ""
#		dbus_signal :slide_changed,"current:u"
#	end
end
