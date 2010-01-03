require 'rubygems'
require 'dbus'
require 'couch_object'

module WesControl
	class Device < DBus::Object
		include CouchObject::Persistable
		database "http://localhost:5984/rooms"
		attr_accessor :name, :module
	
		belongs_to :room, :as => :devices
	
		#this is kind of crazy meta-programming stuff, which
		#I barely even understand. It took me three hours to write
		#these twenty lines. Basically, it lets you say in a class
		#that subclasses Device
		#		state_var :name, :kind => 'string'
		#which is used elsewhere
		@state_vars = {}
		def state_vars; {}; end
		def self.state_var(name, options)
			sym = name
			self.class_eval do
				@state_vars ||= {}
				@state_vars[sym] = options
			end

			self.instance_eval do
				all_state_vars = @state_vars
				define_method("state_vars") do
					all_state_vars
				end
			end
			self.class_eval %{
				def #{sym}= (val)
					@#{sym} = val
					self.save
				end
				def #{sym}
					@#{sym}
				end
			}
		end
		#this is a hook that gets called when the class is subclassed.
		#we need to do this because otherwise subclasses don't get a parent
		#class's state_vars
		def self.inherited(subclass)
			self.instance_variable_get(:@state_vars).each{|name, options|
				subclass.class_eval do
					state_var(name, options)
				end
			} if self.instance_variable_get(:@state_vars)
		end
	
		#protected
		def initialize(name,  bus)
			@name = name
			super("/edu/wesleyan/WesControl/#{name}")
			#main = DBus::Main.new
			#main << bus
			#main.run
		end
	
		def to_couch
			hash = {}
			self.state_vars.each{|var, options|
				options["state"] = eval("@#{var}")
				hash[var] = options
			}
			return hash
		end
	end
end
