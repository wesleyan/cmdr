module Wescontrol
	class Device
		def self.configuration
			@configuration
		end
		class ConfigurationHandler
			attr_reader :configuration
			def initialize
				@configuration = {}
			end
			def method_missing name, args
				@configuration[name] = args
			end
		end
		def self.configure &block
			ch = ConfigurationHandler.new
			ch.instance_eval(&block)
			@configuration ||= {}
			@configuration = ch.configuration.merge @configuration
		end
		
		def self.state_var name, options = {}
			sym = name.to_sym
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
				def #{sym}= val
					if @#{sym} != val
						@#{sym} = val
						state_vars = self.class.instance_variable_get(:@state_vars)
					end
					val
				end
				def #{sym}
					@#{sym}
				end
			}
		end
	end
end