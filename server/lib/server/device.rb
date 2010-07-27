#---
#{
#	name: "Device",
#	depends_on: [],
#	description: "The base class for all devices; never instantiated",
#	author: "Micah Wylde",
#	email: "mwylde@wesleyan.edu"
#}
#---

#This class exists solely to get configuration information out of device files
#As such, it doesn't do anything but that
module Wescontrol
	class Device
		def initialize(name, hash = {})
		end
		
		def self.inherited(subclass)
			subclass.instance_variable_set(:@configuration, @configuration)						
		end
		
			
		class ConfigurationHandler
			attr_reader :configuration
			attr_reader :config_vars
			def initialize
				@configuration = {}
				@config_vars = {}
			end
			def method_missing name, args = nil
				if args.is_a? Hash
					@configuration[name] = args[:default]
					@config_vars[name] = args
				else
					@configuration[name] = args
					@config_vars[name] = {:value => args}
				end
			end
		end
		
		def self.configuration
			@configuration
		end
		
		def self.configure &block
			ch = ConfigurationHandler.new
			ch.instance_eval(&block)
			@configuration ||= {}
			@config_vars ||= {}
			@configuration = @configuration.merge ch.configuration
			@config_vars = @config_vars.merge ch.config_vars
		end
		
		def method_missing(var, *args)
		end
		
		def self.method_missing(var, *args)
		end
	end
end
