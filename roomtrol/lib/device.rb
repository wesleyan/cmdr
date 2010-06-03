module Wescontrol
	class Device
		#this is a hook that gets called when the class is subclassed.
		#we need to do this because otherwise subclasses don't get a parent
		#class's state_vars
		def self.inherited(subclass)
			self.instance_variable_get(:@state_vars).each{|name, options|
				subclass.class_eval do
					state_var(name, options)
				end
			} if self.instance_variable_get(:@state_vars)
			
			self.instance_variable_get(:@config_vars).each{|name|
				subclass.class_eval do
					config_var(name)
				end
			} if self.instance_variable_get(:@config_vars)
			
			self.instance_variable_get(:@command_vars).each{|name, options|
				subclass.class_eval do
					command(name, options)
				end
			} if self.instance_variable_get(:@command_vars)
		end
		
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
		
		def self.state_vars; @state_vars; end
		
		def self.state_var name, options
			sym = name.to_sym
			self.class_eval do
				raise "Must have type field" unless options[:type]
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
						if virtuals = self.state_vars[:#{sym}][:affects]
							virtuals.each{|var|
								puts "<pre>\#{var}: \#{state_vars[var].inspect}</pre>"
								begin
									transformation = self.instance_eval &state_vars[var][:transformation]
									self.send("\#{var}=", transformation)
								rescue
									DaemonKit.logger.error "Transformation on \#{var} failed: \#{$!}"
								end
							}
						end
					end
					val
				end
				def #{sym}
					@#{sym}
				end
			}
			
			if options[:action].class == Proc
				define_method "set_#{name}".to_sym, &options[:action]
			end
		end
		
		def self.virtual_var name, options
			raise "must have :depends_on field" unless options[:depends_on]
			raise "must have :transformation field" unless options[:transformation].class == Proc
			options[:editable] = false
			self.state_var(name, options)
			options[:depends_on].each{|var|
				if @state_vars[var]
					@state_vars[var][:affects] ||= []
					@state_vars[var][:affects] << name
				end
			}
		end
		
		def self.commands; @command_vars; end
		
		def self.command name, options = {}
			if options[:action].class == Proc
				define_method name, &options[:action]
			end
			@command_vars ||= {}
			@command_vars[name] = options
		end
		
		def inspect
			"<#{self.class.to_s}:0x#{object_id.to_s(16)}>"
		end
	end
end