require 'couchrest'
module Wescontrol
	class Device
		attr_accessor :_id, :_rev, :belongs_to, :controller
		
		def initialize(hash = {})
			#TODO: Maybe force name to be provided?
			hash_s = hash.symbolize_keys
			@name = hash_s[:name]
			#TODO: The database uri should not be hard-coded
			@db = CouchRest.database("http://localhost:5984/rooms")
		end

		#this is a hook that gets called when the class is subclassed.
		#we need to do this because otherwise subclasses don't get a parent
		#class's state_vars
		def self.inherited(subclass)
			subclass.instance_variable_set(:@state_vars, {})
			self.instance_variable_get(:@state_vars).each{|name, options|
				subclass.class_eval do
					state_var(name, options.deep_dup)
				end
			} if self.instance_variable_get(:@state_vars)
			
			self.instance_variable_get(:@config_vars).each{|name|
				subclass.class_eval do
					config_var(name)
				end
			} if self.instance_variable_get(:@config_vars)
			
			self.instance_variable_get(:@command_vars).each{|name, options|
				subclass.class_eval do
					command(name, options.deep_dup)
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
								begin
									transformation = self.instance_eval &state_vars[var][:transformation]
									self.send("\#{var}=", transformation)
								rescue
									DaemonKit.logger.error "Transformation on \#{var} failed: \#{$!}"
								end
							}
						end
						if @change_deferrable
							@change_deferrable.set_deferred_status :succeeded, "#{sym}", val
							@change_deferrable = nil
							
							if @auto_register
								@auto_register.each{|block|
									register_for_changes.callback(&block)
								}
							end
						end
						self.save
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
		
		def to_couch
			hash = {:state_vars => {}, :config => {}, :commands => {}}
			
			self.class.configuration.each{|var, value| hash[:config][var] = value}
			
			self.class.state_vars.each{|var, options|
				if options[:type] == :time
					options[:state] = eval("@#{var}.to_i")
				else
					options[:state] = eval("@#{var}")
				end
				hash[:state_vars][var] = options
			}
			
			self.class.commands.each{|var, options| hash[:commands][var] = options}

			return hash
		end
		def self.from_couch(hash)
			device = self.new(hash['attributes'])
			device._id = hash['_id']
			device._rev = hash['_rev']
			device.belongs_to = hash['belongs_to']
			device.controller = hash['controller']
			state_vars = hash['attributes']['state_vars']
			state_vars ||= {}
			hash['attributes']['state_vars'] = nil
			hash['attributes']['command_vars'] = nil

			#merge the contents of the state_vars hash into attributes
			(hash['attributes'].merge(state_vars.each_key{|name|
				if state_vars[name]['kind'] == "time"
					begin
						state_vars[name] = Time.at(state_vars[name]['state'])
					rescue
					end
				else
					state_vars[name] = state_vars[name]['state']
				end
			})).each{|name, value|
				device.instance_variable_set("@#{name}", value)
			}
			return device
		end
		def self.from_doc(id)
			from_couch(CouchRest.database(@database).get(id))
		end
		
		def save
			retried = false
			begin
				hash = self.to_couch
				doc = {'attributes' => hash, 'class' => self.class, 'belongs_to' => @belongs_to, 'controller' => @controller, 'device' => true}
				if @_id && @_rev
					doc["_id"] = @_id
					doc["_rev"] = @_rev
				end
				#@_rev = @db.save_doc(doc)['rev']
			rescue => e
				if !retried
					retried = true
					retry
				else
					DaemonKit.logger.exception e
				end
			end
		end
		
		def register_for_changes
			@change_deferrable ||= EM::DefaultDeferrable.new
			@change_deferrable
		end
		
		def auto_register_for_changes(&block)
			@auto_register ||= []
			@auto_register << block
			register_for_changes.callback(&block)
		end
		
	end
end


#Thes methods dup all objects inside the hash/array as well as the data structure itself
#However, because we don't check for cycles, they will cause an infinite loop if present
class Object
	def deep_dup
		begin
			self.dup
		rescue
			self
		end
	end
end

class Hash
	def symbolize_keys!
		t = self.dup
		self.clear
		t.each_pair{|k, v| self[k.to_sym] = v}
		self
	end
	def symbolize_keys
		t = {}
		self.each_pair{|k, v| t[k.to_sym] = v}
		t
	end
	def deep_dup
		new_hash = {}
		self.each{|k, v| new_hash[k] = v.deep_dup}
		new_hash
	end
end

class Array
	def deep_dup
		self.collect{|x| x.deep_dup}
	end
end