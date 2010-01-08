module Wescontrol
	class Device < DBus::Object
		attr_accessor :_id, :_rev, :belongs_to
		@database = "http://localhost:5984/rooms"

	
		#this is kind of crazy meta-programming stuff, which
		#I barely even understand. It took me three hours to write
		#these twenty lines. Basically, it lets you say in a class
		#that subclasses Device
		#		state_var :name, :kind => 'string'
		#which is used elsewhere
		@state_vars = {}
		@config_vars = []
		def state_vars; {}; end
		def config_vars; []; end
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
					if @#{sym} != val
						@#{sym} = val
						self.save
					end
				end
				def #{sym}
					@#{sym}
				end
			}
		end
		def self.config_var(name)
			self.class_eval do
				@config_vars ||= []
				@config_vars.push(name).uniq!
			end

			self.instance_eval do
				all_config_vars = @config_vars
				define_method("config_vars") do
					all_config_vars
				end
			end
			self.class_eval %{
				def #{name}= (val)
					@#{name} = val
					self.save
				end
				def #{name}
					@#{name}
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
			
			self.instance_variable_get(:@config_vars).each{|name|
				subclass.class_eval do
					config_var(name)
				end
			} if self.instance_variable_get(:@config_vars)
		end
		
		config_var :name
	
		#protected
		def initialize(hash)
		#TODO: Maybe force name to be provided?
			hash_s = hash.symbolize_keys
			@name = hash_s[:name]
			#TODO: The database uri should not be hard-coded
			@db = CouchRest.database("http://localhost:5984/rooms")
			super("/edu/wesleyan/WesControl/#{hash_s[:name]}")
		end
	
		def to_couch
			hash = {'state_vars' => {}}
			
			self.config_vars.each{|var| hash[var] = eval("@#{var}")}
			
			self.state_vars.each{|var, options|
				options["state"] = eval("@#{var}")
				hash['state_vars'][var] = options
			}
			
			return hash
		end
		
		def self.from_couch(hash)
			device = self.new(hash['attributes'])
			device._id = hash['_id']
			device._rev = hash['_rev']
			device.belongs_to = hash['belongs_to']
			state_vars = hash['attributes']['state_vars']
			state_vars ||= {}
			hash['attributes']['state_vars'] = nil
			(hash['attributes'].merge(state_vars.each_key{|name| 
				state_vars[name] = state_vars[name]['state']
			})).each{|name, value|
				device.instance_variable_set("@#{name}", value)
			}
			return device
		end
		
		def self.from_doc(id)
			from_couch(CouchRest.database(@database).get(id))
		end
		
		def save
			hash = self.to_couch
			doc = {'attributes' => hash, 'class' => self.class, 'belongs_to' => @belongs_to}
			if @_id && @_rev
				doc["_id"] = @_id
				doc["_rev"] = @_rev
			end
			@_rev = @db.save_doc(doc)['rev']
		end
		
		def inspect
			"<#{self.class.inspect}:#{self.object_id}>"
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
end

