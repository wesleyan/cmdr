require 'rubygems'
require 'dbus'
#require '/usr/local/wescontrol/daemon/dbus_fix.rb'


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
	
	def state_vars (*syms)
		syms.each do |sym|
			class_eval %{
				def #{sym}= (val)
					@#{sym} = val
					variable_updated(sym, val)
				end
			}
		end
	end
	
	def variable_updated(var, value)
			
	end
end
