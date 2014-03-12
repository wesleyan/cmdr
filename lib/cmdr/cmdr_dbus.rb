# Copyright (C) 2014 Wesleyan University
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'dbus'
module Cmdr
	class CmdrDBus < DBus::Object
		attr_accessor :cmdr
		def initialize devices
			super("/edu/wesleyan/Cmdr/controller")
			@bus = DBus::SystemBus.instance
			@service = @bus.request_service("edu.wesleyan.Cmdr")
			@service.export(self)
			
			devices.each{|device|
				deviceclass = Class.new(DBus::Object)
				deviceclass.instance_variable_set(:@device, device)
				deviceclass.__send__ :define_method, :do_dbus_method do |method, type, *args|
					response = nil
					error = ""

					device = self.class.instance_variable_get(:@device)
					begin
						#using the __send__ form because DBus::Object has its own send method
						response = device.__send__(method.to_sym, *args)
					rescue
						puts "ERROR: #{$!}"
						error = $!.to_s
					end
					responses = []
					if !response
						type_map = {"b" => false, "s" => "", "u" => 0, "d" => 0.0}
						responses = [type_map[type]]
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
				deviceclass.class_eval do
					type_map = {
						:boolean => 'b',
						:string => 's',
						:number => 'u',
						:percentage => 'd',
						:decimal => 'd',
						:option => 's'
					}
					dbus_interface "edu.wesleyan.Cmdr.#{device.interface}" do
						@device.state_vars.each do |name, options|
							type = type_map[options[:kind].to_sym]
							dbus_method name, "out #{name}:#{type}" do |*args|
								return self.do_dbus_method(name, type, *args)
							end
							if options['editable'] == nil || options['editable']
								dbus_method "set_#{name}".to_sym, "in #{name}:#{type}, out response:s" do |*args|
									return self.do_dbus_method("set_#{name}", "s", *args)
								end
							end
							dbus_signal "#{name}_changed".to_sym, "#{name}:#{type}"
						end
					end
				end

				device_dbus = deviceclass.new("/edu/wesleyan/Cmdr/#{device.name}")
				@service.export(device_dbus)
				
				device.auto_register_for_changes {|var, val|
					device_dbus.__send__("#{var}_changed", val)
				}
			}
		end
		def start
			puts "Starting DBus on edu.wesleyan.Cmdr"
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
		dbus_interface "edu.wesleyan.Cmdr.controller" do
			dbus_method :room_name, "out name:s" do
				[self.name]
			end
		end
	end
end
