require_relative 'spec_helper.rb'
require_relative '../lib/roomtrol/device.rb'
require_relative '../lib/roomtrol/constants.rb'
require 'eventmachine'
require 'mq'
require 'couchrest'

RSpec::Runner.configure do |config|
	#For some reason in Ruby 1.9.2 class definition constants leak between tests, causing errors
	config.before(:each) {
		Object.send(:remove_const, :DeviceSubclass) if Object.constants.include? :DeviceSubclass
		Object.send(:remove_const, :DeviceSubSubclass) if Object.constants.include? :DeviceSubSubclass
	}
end

describe "allow configuration" do
	it "should respond to configure" do
		class DeviceSubclass < Wescontrol::Device
			configure do
			end
		end
	end
	
	it "should set configuration info" do
		class DeviceSubclass < Wescontrol::Device
			configure do
				baud 9600
				port "/dev/something"
			end
		end
		DeviceSubclass.configuration[:baud].should == 9600
		DeviceSubclass.configuration[:port].should == "/dev/something"
	end
	
	it "should allow variable configuration" do
		class DeviceSubclass < Wescontrol::Device
			configure do
				port :type => :string
			end
		end
		DeviceSubclass.configuration.size.should == 1
		DeviceSubclass.configuration.each{|k,v| k.should == :port}
	end
	
	it "should allow default values for variable configuration" do
		class DeviceSubclass < Wescontrol::Device
			configure do
				baud :type => :integer, :default => 9600
			end
		end
		DeviceSubclass.configuration.size.should == 1
		DeviceSubclass.configuration.each{|k,v| k.should == :baud; v.should == 9600}
	end
	
	it "should allow multiple configuration blocks" do
		class DeviceSubclass < Wescontrol::Device
			configure do
				baud 9600
				port "/dev/something"
			end
			configure do
				something "else"
			end
		end
		DeviceSubclass.configuration[:baud].should == 9600
		DeviceSubclass.configuration[:port].should == "/dev/something"
		DeviceSubclass.configuration[:something].should == "else"
	end
	
	it "should not allow multiple values in configuration" do
		proc {
			class DeviceSubclass < Wescontrol::Device
				configure do
					baud 9600, 400, "no"
				end
			end
		}.should raise_error
	end
	
	it "should share configuration with subclasses" do
		class DeviceSubclass < Wescontrol::Device
			configure do
				baud 9600
				port "/dev/something"
			end
		end
		class DeviceSubSubclass < DeviceSubclass
			configure do
				baud 2400
				parity 0
			end
		end
		DeviceSubSubclass.configuration.should == {:baud => 2400, :port => "/dev/something", :parity => 0}
	end
end

describe "deal with state_vars properly" do
	it "should respond to state_var" do
		class DeviceSubclass < Wescontrol::Device
			state_var :power, :type => :boolean
		end
	end
	
	it "should require a :type field" do
		proc {
			class DeviceSubclass < Wescontrol::Device
				state_var :power
			end
		}.should raise_error
		
		proc {
			class DeviceSubclass < Wescontrol::Device
				state_var :power, :someting => :else
			end
		}.should raise_error
	end

	it "should create accessor methods for state_var" do
		class DeviceSubclass < Wescontrol::Device
			state_var :text, :type => :string
		end
		ds = DeviceSubclass.new("device")
		ds.text = "name"
		ds.text.should == "name"
	end
	
	it "should inherit state_vars" do
		class DeviceSubclass < Wescontrol::Device
			state_var :text, :type => :string
		end
		class DeviceSubSubclass < DeviceSubclass
		end
		dss = DeviceSubSubclass.new("device")
		dss.text = "name"
		dss.text.should == "name"
		
		dss.state_vars[:text].should == {:type => :string, :state => "name"}
	end
	
	it "should not share state_var values between subclasses" do
		class DeviceSubclass < Wescontrol::Device
			state_var :text, :type => :string
		end
		class DeviceSubSubclass < DeviceSubclass
			state_var :another, :type => :string
		end
		ds = DeviceSubclass.new("d1")
		ds.text = "name"
		ds.text.should == "name"
		
		dss = DeviceSubSubclass.new("d2")
		dss.state_vars[:text].should == {:type => :string}
		dss.text = "another"
		dss.text.should == "another"
		ds.text.should == "name"
		
		ds.text = "something"
		ds.text.should == "something"
		dss.text.should == "another"
		
		dss.another = "hello"
		dss.another.should == "hello"
		proc {
			ds.another = "test"
		}.should raise_error
	end
	
	it "should set all state_vars in state_vars hash and allow access" do
		class DeviceSubclass < Wescontrol::Device
			state_var :text, :type => :string
			state_var :something, :type => :option, :options => (1..6).to_a
		end
		DeviceSubclass.state_vars[:text].should == {:type => :string}
		DeviceSubclass.state_vars[:something].should == {
			:type => :option,
			:options => [1,2,3,4,5,6]
		}
	end
	
	it "should create set_ methods if :action is provided" do
		class DeviceSubclass < Wescontrol::Device
			state_var :power, :type => :string, :action => proc {|x| "hello #{x}"}
		end
		ds = DeviceSubclass.new("device")
		ds.set_power("micah").should == "hello micah"
	end
end

describe "do virtual vars" do
	it "should allow creation of virtual vars" do
		class DeviceSubclass < Wescontrol::Device
			state_var :text, :type => :string
			virtual_var :capital_name, 
				:type => :string, 
				:depends_on => [:text], 
				:transformation => proc {
					name.upcase
				}
		end
		ds = DeviceSubclass.new("device")
		ds.capital_name
	end
	it "should require a depends_on and transformation field" do
		proc {
			class DeviceSubclass < Wescontrol::Device
				state_var :text, :type => :string
				virtual_var :capital_name, :type => :string
			end
		}.should raise_error
	end
	it "should recalculate virtual vars" do
		class DeviceSubclass < Wescontrol::Device
			state_var :text, :type => :string
			virtual_var :capital_name, 
				:type => :string, 
				:depends_on => [:text], 
				:transformation => proc {
					text.upcase
				}
		end
		ds = DeviceSubclass.new("device")
		ds.text = "micah"
		ds.capital_name.should == "MICAH"
	end
	it "should work with multiple depends_on vars" do
		class DeviceSubclass < Wescontrol::Device
			state_var :first, :type => :string
			state_var :last, :type => :string
			virtual_var :full_name, 
				:type => :string, 
				:depends_on => [:first, :last], 
				:transformation => proc {
					"#{first} #{last}"
				}
		end
		ds = DeviceSubclass.new("device")
		ds.first = "Micah"
		ds.last = "Wylde"
		ds.full_name.should == "Micah Wylde"
	end
	it "should inherit virtual_vars properly" do
		class DeviceSubclass < Wescontrol::Device
			state_var :first, :type => :string
			state_var :last, :type => :string
			virtual_var :full_name, 
				:type => :string, 
				:depends_on => [:first, :last], 
				:transformation => proc {
					"#{first} #{last}"
				}
		end
		DeviceSubclass.state_vars[:first][:affects].should == [:full_name]
		class DeviceSubSubclass < DeviceSubclass
			virtual_var :full_name_inverse, 
				:type => :string, 
				:depends_on => [:first, :last], 
				:transformation => proc {
					"#{last} #{first}"
				}
		end
		DeviceSubclass.state_vars[:first][:affects].should == [:full_name]
		ds = DeviceSubclass.new("device")
		ds.first = "Micah"
		ds.last = "Wylde"
		ds.full_name.should == "Micah Wylde"
		dss = DeviceSubSubclass.new("device")
		dss.first = "Micah"
		dss.last = "Wylde"
		dss.full_name.should == "Micah Wylde"
		dss.first = "James"
		dss.last = "Smith"
		dss.full_name.should == "James Smith"
		dss.full_name_inverse.should == "Smith James"
	end
end

describe "deal with commands" do
	it "should allow setting commands" do
		class DeviceSubclass < Wescontrol::Device
			command :do_thing
		end
	end
	it "should allow settings command with actions" do
		class DeviceSubclass < Wescontrol::Device
			command :do_thing, :action => proc{"hello"}
		end
		ds = DeviceSubclass.new("device")
		ds.do_thing.should == "hello"
	end
	it "should allow accessing commands" do
		class DeviceSubclass < Wescontrol::Device
			command :something
			command :another, :type => :array
		end
		DeviceSubclass.commands[:something].should_not == nil
		DeviceSubclass.commands[:another].should == {:type => :array}
	end
	it "should allow commands with arguments" do
		class DeviceSubclass < Wescontrol::Device
			command :do_thing, :type => "percentage", :action => proc{|p| (p*100).to_i}
			
		end
		ds = DeviceSubclass.new("device")
		ds.do_thing(0.1).should == 10
	end
end

describe "persist to couchdb database" do
	it "should create hash representation of device" do
		class DeviceSubclass < Wescontrol::Device
			configure do
				data_bits 8
				baud :type => :integer, :default => 9600
				port :type => :port
			end
			state_var :name, :type => :string
			state_var :brightness, :type => :percentage
			command :focus, :type => :percentage
		end
		ds = DeviceSubclass.new("device")
		ds.name = "Projector"
		ds.brightness = 0.8
		ds.to_couch.should == {
			:config => {
				:data_bits => 8,
				:baud => 9600,
				:port => nil
			},
			:state_vars => {
				:name => {
					:type => :string,
					:state => "Projector"
				},
				:brightness => {
					:type => :percentage,
					:state => 0.8
				}
			},
			:commands => {
				:focus => {
					:type => :percentage
				}
			}
		}
	end
	
	it "should load a new device from hash" do
		class DeviceSubclass < Wescontrol::Device
			configure do
				data_bits 8
				baud :type => :integer, :default => 9600
				port :type => :port
			end
			state_var :name, :type => :string
			state_var :brightness, :type => :percentage
			command :focus, :type => :percentage
		end
		
		ds = DeviceSubclass.from_couch({
			"_id" => "0a2392bb27551acf35cdd1ca621ec26b",
			"_rev" => "1654-ff63755fb7999e3d6fb97cc011575c38",
			"attributes" => {
				"name" => "Projector",
				"config" => {
					"data_bits" => 7,
					"baud" => 19200,
					"port" => "/dev/null",
				},
				"state_vars" => {
					"brightness" => {
						"type" => "percentage",
						"state" => 0.8
					}
				},
				"commands" => {
					"focus" => {
						"type" => "percentage"
					}
				}
			},
			"belongs_to" => "c180fad1e1599512ea68f1748eb601ea"
		})
		
		ds.name.should == "Projector"
		ds.brightness.should == 0.8
		ds.name = "Extron"
		ds.name.should == "Extron"
		ds.state_vars[:name].should == {:type => :string, :state => "Extron"}
		ds.configuration[:data_bits].should == 8
		ds.configuration[:port].should == "/dev/null"
		ds.configuration[:baud].should == 19200
		ds._id.should == "0a2392bb27551acf35cdd1ca621ec26b"
	end
end	
describe "handling requests from amqp" do
	it "should work for setting vars" do
		Thread.abort_on_exception = true
		class DeviceSubclass < Wescontrol::Device
			state_var :power, :type => :boolean
			def set_power state
				self.power = state
			end
		end
		
		ds = DeviceSubclass.new("Extron", {}, TEST_DB, "roomtrol:test:dqueue:1")
		ds.power = false
		ds.power.should == false
		json = '{
			"id": "FF00F317-108C-41BD-90CB-388F4419B9A1",
			"queue": "roomtrol:test:3",
			"type": "state_set",
			"var": "power",
			"value": true
		}'
		AMQP.start(:host => '127.0.0.1') do
			amq = MQ.new
			amq.queue(ds.dqueue).purge
			amq.queue('roomtrol:test:3').purge
			ds.run
			amq.queue(ds.dqueue).publish(json)
			amq.queue('roomtrol:test:3').subscribe{|msg|
				@msg = msg
				AMQP.stop do
					EM.stop
				end
			}
			
			EM::add_periodic_timer(3) do
				AMQP.stop do
					EM.stop
				end
			end
		end
		@msg.class.should == String
		JSON.parse(@msg).should == {
			"id" => "FF00F317-108C-41BD-90CB-388F4419B9A1",
			"result" => true
		}
		ds.power.should == true
	end
	it "should work for commands" do
		Thread.abort_on_exception = true
		class DeviceSubclass < Wescontrol::Device
			command :power, :action => proc{|on| "power=#{on}"}
		end
		
		ds = DeviceSubclass.new("Extron", {}, TEST_DB, "roomtrol:test:dqueue:2")
		
		json = '{
			"id": "FF00F317-108C-41BD-90CB-388F4419B9A1",
			"queue": "roomtrol:test:2",
			"type": "command",
			"method": "power",
			"args": [true]
		}'
		AMQP.start(:host => '127.0.0.1') do
			amq = MQ.new
			amq.queue(ds.dqueue).purge
			amq.queue('roomtrol:test:2').purge
			ds.run
			amq.queue(ds.dqueue).publish(json)
			amq.queue('roomtrol:test:2').subscribe{|msg|
				@msg = msg
				AMQP.stop do
					EM.stop
				end
			}
			
			EM::add_periodic_timer(3) do
				AMQP.stop do
					EM.stop
				end
			end
		end
		@msg.class.should == String
		JSON.parse(@msg).should == {
			"id" => "FF00F317-108C-41BD-90CB-388F4419B9A1",
			"result" => "power=true"
		}
	end
	it "should return requested data" do
		Thread.abort_on_exception = true
		class DeviceSubclass < Wescontrol::Device
			state_var :name, :type => :string
		end
		
		ds = DeviceSubclass.new("Extron", {}, TEST_DB, "roomtrol:test:dqueue:3")
		
		json = '{
			"id": "FF00F317-108C-41BD-90CB-388F4419B9A1",
			"queue": "roomtrol:test:1",
			"type": "state_get",
			"var": "name"
		}'
		AMQP.start(:host => '127.0.0.1') do
			amq = MQ.new
			amq.queue(ds.dqueue).purge
			amq.queue('roomtrol:test:1').purge
			ds.run
			amq.queue(ds.dqueue).publish(json)
			amq.queue('roomtrol:test:1').subscribe{|msg|
				@msg = msg
				AMQP.stop do
					EM.stop
				end
			}
			
			EM::add_periodic_timer(3) do
				AMQP.stop do
					EM.stop
				end
			end
		end
		JSON.parse(@msg).should == {
			"id" => "FF00F317-108C-41BD-90CB-388F4419B9A1",
			"result" => "Extron"
		}
	end
	it "should work under stressful situations" do
		Thread.abort_on_exception = true
		@times = 1000
		class DeviceSubclass < Wescontrol::Device
			command :zoom, :action => proc{|zoom| "zoom=#{zoom}"}
			#state_var :power, :type => :boolean, :action => proc{|on| this.power = on}
			state_var :brightness, :type => :integer, :action => proc{|v| self.brightness = v}
			state_var :volume, :type => :integer, :action => proc{|v| self.volume = v}
		end
				
		ds = DeviceSubclass.new("Extron", {}, TEST_DB, "roomtrol:test:dqueue:4")	
		
		@states = {:brightness => 1, :volume => 1}
		
		types = [:state_get, :state_set, :command]
		@messages = []
		@recv = 0
		srand(124209350982)
		AMQP.start(:host => '127.0.0.1') do
			EM::add_periodic_timer(10) do
				AMQP.stop do
					EM.stop
				end
			end
			amq = MQ.new
			amq.queue(ds.dqueue).purge
			amq.queue('roomtrol:test:4').purge
			ds.run
			amq.queue('roomtrol:test:4').subscribe{|json|
				msg = JSON.parse(json)
				if @messages[msg["id"]].is_a? Symbol
					#puts "Symbol"
					#msg["result"].should == ds.send(@messages[msg["id"]])
				else
					msg["result"].should == @messages[msg["id"]]
				end
				@recv+=1
				if @recv == @times
					AMQP.stop do
						EM.stop
					end
				end
			}
			@times.times{|i|
				msg = {:id => i, :queue => "roomtrol:test:4"}
				case types[rand(3)]
				when :state_get then
					msg[:type] = :state_get
					msg[:var] = @states.keys[rand(2)]
					@messages[i] = msg[:var]
				when :state_set then
					msg[:type] = :state_set
					msg[:var] = @states.keys[rand(2)]
					msg[:value] = rand(100)
					@messages[i] = msg[:value]
				when :command then
					msg[:type] = :command
					msg[:method] = :zoom
					msg[:args] = rand(100)
					@messages[i] = "zoom=#{msg[:args]}"
				end
				amq.queue(ds.dqueue).publish(msg.to_json)
			}
		end
		@recv.should == @times
	end
	describe "Event handling" do
		it "should send events when device state vars change" do
			AMQP.start(:host => '127.0.0.1') do
				amq = MQ.new
				amq.queue(Wescontrol::EVENT_QUEUE).purge
				EM::add_periodic_timer(0.5) do
					AMQP.stop do
						EM.stop
					end
				end
			end
			class DeviceSubclass < Wescontrol::Device
				state_var :text, :type => :string
			end
			
			ds = DeviceSubclass.new("Extron")
			ds._id = "device_id"
			ds.belongs_to = "room_id"
			@recv = 5
			ds.text = "model#{@recv}"
			AMQP.start(:host => '127.0.0.1') do
				ds.run
				@recv.times{|i|
					ds.text = "model#{ds.text[-1].to_i-1}"
				}
				EM::add_periodic_timer(5) do
					AMQP.stop do
						EM.stop
					end
				end
				amq = MQ.new
				amq.queue(Wescontrol::EVENT_QUEUE).subscribe{|json|
					msg = JSON.parse(json)
					Time.at(msg.delete('time')).hour.should == Time.now.hour
					msg.should == {
						'state_update' => true,
						'var' => 'text',
						'now' => "model#{@recv-1}",
						'was' => "model#{@recv}",
						'device' => ds._id,
						'room' => ds.belongs_to,
						'update' => true,
						'severity' => 0.1
					}
					@recv -= 1
					if @recv == 0
						AMQP.stop do
							EM.stop
						end
					end
				}
			end
			@recv.should == 0
		end
	end
end
