require 'dbus'
module Wescontrol
	class WescontrolDBus < DBus::Object
		attr_accessor :wescontrol
		def initialize devices
			super("/edu/wesleyan/WesControl/controller")
			@bus = DBus::SystemBus.instance
			@service = @bus.request_service("edu.wesleyan.WesControl")
			@service.export(self)
			
			type_map = {
				:boolean => 'b',
				:string => 's',
				:number => 'u',
				:percentage => 'd',
				:option => 's'
			}
			
			devices.each{|device|
				self.class.class_eval %{
					class #{device.name.capitalize}DBus < DBus::Object
						dbus_interface "edu.wesleyan.WesControl.#{device.name}" do
							@@device.state_vars.each do |name, options|
								dbus_method name, "out \#{name}:\#{type_map[options[:kind]]}" do |*args|
									return [@@device.__send__(name.to_sym)]
								end
								if options['editable'] == nil || options['editable']
									dbus_method "set_\#{name}", "in \#{name}:\#{type_map[options[:kind]]}, out:response:s" do |*args|
										return [@@device.__send__("set_\#{name}", *args)]
									end
								end
							end
						end
						@@device.state_vars.each do |name, options|
							dbus_signal "\#{name}_changed".to_sym, "\#{name}:\#{type_map[options[:kind]]}"
						end
					end
				}
				dbus_class = eval("WescontrolDBus::#{device.name.capitalize}DBus")
				dbus_class
				device_dbus = .new(device)
				@service.export(device_dbus)
				
				device.auto_register_for_changes {|var, val|
					device_dbus.__send__("#{var}_changed", val)
				}
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
