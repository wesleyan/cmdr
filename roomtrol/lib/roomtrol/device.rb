$eventmachine_library = :pure_ruby
require 'couchrest'
require 'mq'
require 'json'

module EventMachine
	class Connection
		def associate_callback_target(sig) #:nodoc:
		#   For reasons unknown, this method was commented out
		#   in recent version of EM. We need it, though, for AMQP.
		end
	end
end
module Wescontrol
	class Device
		attr_accessor :_id, :_rev, :belongs_to, :controller
		attr_reader :name
				
		def initialize(name, hash = {})
			#TODO: Maybe force name to be provided?
			hash_s = hash.symbolize_keys
			@name = name
			hash.each{|var, value|
				configuration[var.to_sym] = value
			} if configuration
			#TODO: The datab ase uri should not be hard-coded
			@db = CouchRest.database("http://localhost:5984/rooms")
		end
		
		def run
			AMQP.start(:host => '127.0.0.1'){
				@amq_responder = MQ.new
				handle_feedback = proc {|feedback, req, resp, job|
					if feedback.is_a? EM::Deferrable
						feedback.callback do |fb|
							resp["result"] = fb
							@amq_responder.queue(req["queue"]).publish(resp.to_json)
						end
						feedback.errback do |error|
							resp["error"] = error
							@amq_responder.queue(req["queue"]).publish(resp.to_json)
						end
					else
						resp["result"] = feedback
						@amq_responder.queue(req["queue"]).publish(resp.to_json)
					end
				}
				
				amq = MQ.new
				DaemonKit.logger.info("Waiting for messages on roomtrol:dqueue:#{@name}")
				amq.queue("roomtrol:dqueue:#{@name}").subscribe{ |msg|
					DaemonKit.logger.debug("Received message: #{msg}")
					req = JSON.parse(msg)
					resp = {:id => req["id"]}
					case req["type"]
					when "command" then handle_feedback.call(self.send(req["method"], *req["args"]), req, resp)
					when "state_set" then handle_feedback.call(self.send("set_#{req["var"]}", req["value"]), req, resp)
					when "state_get" then handle_feedback.call(self.send(req["var"]), req, resp)
					else DaemonKit.logger.error "Didn't match: #{req["type"]}" 
					end
				}
			}
		end

#		This is what requests look like:
#		{
#			id: "FF00F317-108C-41BD-90CB-388F4419B9A1",
#			queue: "roomtrol:http"
#			type: "command",
#			method: "power",
#			args: [true]
#		}
#		{
#			id: "D62F993B-E036-417C-948B-FEA389480984",
#			queue: "roomtrol:websocket"
#			type: "state_set",
#			var: "input",
#			value: 4
#		}
#		{
#			id: "DD2297B4-6982-4804-976A-AEA868564DF3",
#			queue: "roomtrol:http"
#			type: "state_get",
#			var: "input"
#		}

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
			
			subclass.instance_variable_set(:@configuration, @configuration)
						
			self.instance_variable_get(:@command_vars).each{|name, options|
				subclass.class_eval do
					command(name, options.deep_dup)
				end
			} if self.instance_variable_get(:@command_vars)
		end
		
		def self.configuration
			@configuration
		end
		
		def configuration
			self.class.instance_variable_get(:@configuration)
		end
		def config_vars
			self.class.instance_variable_get(:@config_vars)
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
		
		def self.configure &block
			ch = ConfigurationHandler.new
			ch.instance_eval(&block)
			@configuration ||= {}
			@config_vars ||= {}
			@configuration = @configuration.merge ch.configuration
			@config_vars = @config_vars.merge ch.config_vars
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
						DaemonKit.logger.debug sprintf("%-10s = %s\n", "#{sym}", val.to_s)
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
		def commands; self.class.commands; end
		
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
			
			if config_vars
				config_vars.each{|var, options|
					hash[:config][var] = configuration[var]
				}
			end
			
			self.class.state_vars.each{|var, options|
				if options[:type] == :time
					options[:state] = eval("@#{var}.to_i")
				else
					options[:state] = eval("@#{var}")
				end
				hash[:state_vars][var] = options
			}
			if commands
				commands.each{|var, options| hash[:commands][var] = options}
			end

			return hash
		end
		def self.from_couch(hash)
			config = {}
			hash['attributes']['config'].each{|var, value|
				config[var] = value
			}
			device = self.new(hash['attributes']['name'], config)
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
				@_rev = @db.save_doc(doc)['rev']
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