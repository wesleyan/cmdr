require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/../lib/device.rb'
require 'eventmachine'
require 'mq'
# Time to add your specs!
# http://rspec.info/


Spec::Runner.configure do |config|
	config.before(:each) {
		#this creates a mock save method so that nothing actually gets
		#saved to the database. There's probably a better way to do this,
		#involving mocking frameworks or a testing db.
		class DeviceTest < Wescontrol::Device
			def save
			end
		end
	}
end

describe "allow configuration" do
  
	it "should respond to configure" do
		class DeviceSubclass < DeviceTest
			configure do
			end
		end
	end
	
	it "should set configuration info" do
		class DeviceSubclass < DeviceTest
			configure do
				baud 9600
				port "/dev/something"
			end
		end
		DeviceSubclass.configuration[:baud].should == 9600
		DeviceSubclass.configuration[:port].should == "/dev/something"
	end
	
	it "should allow empty configuration" do
		class DeviceSubclass < DeviceTest
			configure do
				port
			end
		end
		DeviceSubclass.configuration.size.should == 1
		DeviceSubclass.configuration.each{|k,v| k.should == :port}
	end
	
	it "should allow multiple configuration blocks" do
		class DeviceSubclass < DeviceTest
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
			class DeviceSubclass < DeviceTest
				configure do
					baud 9600, 400, "no"
				end
			end
		}.should raise_error
	end
end

describe "deal with state_vars properly" do
	it "should respond to state_var" do
		class DeviceSubclass < DeviceTest
			state_var :name, :type => :string
		end
	end
	
	it "should require a :type field" do
		proc {
			class DeviceSubclass < DeviceTest
				state_var :name
			end
		}.should raise_error
		
		proc {
			class DeviceSubclass < DeviceTest
				state_var :name, :someting => :else
			end
		}.should raise_error
	end

	it "should create accessor methods for state_var" do
		class DeviceSubclass < DeviceTest
			state_var :name, :type => :string
		end
		ds = DeviceSubclass.new
		ds.name = "name"
		ds.name.should == "name"
	end
	
	it "should inherit state_vars" do
		class DeviceSubclass < DeviceTest
			state_var :name, :type => :string
		end
		class DeviceSubSubclass < DeviceSubclass
		end
		dss = DeviceSubSubclass.new
		dss.name = "name"
		dss.name.should == "name"
		
		dss.state_vars[:name].should == {:type => :string}
	end
	
	it "should not share state_var values between subclasses" do
		class DeviceSubclass < DeviceTest
			state_var :name, :type => :string
		end
		class DeviceSubSubclass < DeviceSubclass
			state_var :another, :type => :string
		end
		ds = DeviceSubclass.new
		ds.name = "name"
		ds.name.should == "name"
		
		dss = DeviceSubSubclass.new
		dss.state_vars[:name].should == {:type => :string}
		dss.name = "another"
		dss.name.should == "another"
		ds.name.should == "name"
		
		ds.name = "something"
		ds.name.should == "something"
		dss.name.should == "another"
		
		dss.another = "hello"
		dss.another.should == "hello"
		proc {
			ds.another = "test"
		}.should raise_error
	end
	
	it "should set all state_vars in state_vars hash and allow access" do
		class DeviceSubclass < DeviceTest
			state_var :name, :type => :string
			state_var :something, :type => :option, :options => (1..6).to_a
		end
		DeviceSubclass.state_vars[:name].should == {:type => :string}
		DeviceSubclass.state_vars[:something].should == {
			:type => :option,
			:options => [1,2,3,4,5,6]
		}
	end
	
	it "should create set_ methods if :action is provided" do
		class DeviceSubclass < DeviceTest
			state_var :power, :type => :string, :action => proc {|x| "hello #{x}"}
		end
		ds = DeviceSubclass.new
		ds.set_power("micah").should == "hello micah"
	end
end

describe "do virtual vars" do
	it "should allow creation of virtual vars" do
		class DeviceSubclass < DeviceTest
			state_var :name, :type => :string
			virtual_var :capital_name, 
				:type => :string, 
				:depends_on => [:name], 
				:transformation => proc {
					name.upcase
				}
		end
		ds = DeviceSubclass.new
		ds.capital_name
	end
	it "should require a depends_on and transformation field" do
		proc {
			class DeviceSubclass < DeviceTest
				state_var :name, :type => :string
				virtual_var :capital_name, :type => :string
			end
		}.should raise_error
	end
	it "should recalculate virtual vars" do
		class DeviceSubclass < DeviceTest
			state_var :name, :type => :string
			virtual_var :capital_name, 
				:type => :string, 
				:depends_on => [:name], 
				:transformation => proc {
					name.upcase
				}
		end
		ds = DeviceSubclass.new
		ds.name = "micah"
		ds.capital_name.should == "MICAH"
	end
	it "should work with multiple depends_on vars" do
		class DeviceSubclass < DeviceTest
			state_var :first, :type => :string
			state_var :last, :type => :string
			virtual_var :full_name, 
				:type => :string, 
				:depends_on => [:first, :last], 
				:transformation => proc {
					"#{first} #{last}"
				}
		end
		ds = DeviceSubclass.new
		ds.first = "Micah"
		ds.last = "Wylde"
		ds.full_name.should == "Micah Wylde"
	end
	it "should inherit virtual_vars properly" do
		class DeviceSubclass < DeviceTest
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
		ds = DeviceSubclass.new
		ds.first = "Micah"
		ds.last = "Wylde"
		ds.full_name.should == "Micah Wylde"
		dss = DeviceSubSubclass.new
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
		class DeviceSubclass < DeviceTest
			command :do_thing
		end
	end
	it "should allow settings command with actions" do
		class DeviceSubclass < DeviceTest
			command :do_thing, :action => proc{"hello"}
		end
		ds = DeviceSubclass.new
		ds.do_thing.should == "hello"
	end
	it "should allow accessing commands" do
		class DeviceSubclass < DeviceTest
			command :something
			command :another, :type => :array
		end
		DeviceSubclass.commands[:something].should_not == nil
		DeviceSubclass.commands[:another].should == {:type => :array}
	end
	it "should allow commands with arguments" do
		class DeviceSubclass < DeviceTest
			command :do_thing, :type => "percentage", :action => proc{|p| (p*100).to_i}
			
		end
		ds = DeviceSubclass.new
		ds.do_thing(0.1).should == 10
	end
end

describe "persist to couchdb database" do
	it "should create hash representation of device" do
		class DeviceSubclass < DeviceTest
			configure do
				baud 9600
			end
			state_var :name, :type => :string
			state_var :brightness, :type => :percentage
			command :focus, :type => :percentage
		end
		ds = DeviceSubclass.new
		ds.name = "Projector"
		ds.brightness = 0.8
		ds.to_couch.should == {
			:config => {
				:baud => 9600
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
		class DeviceSubclass < DeviceTest
			configure do
				baud 9600
			end
			state_var :name, :type => :string
			state_var :brightness, :type => :percentage
			command :focus, :type => :percentage
		end
		
		ds = DeviceSubclass.from_couch({
			"_id" => "0a2392bb27551acf35cdd1ca621ec26b",
			"_rev" => "1654-ff63755fb7999e3d6fb97cc011575c38",
			"attributes" => {
				"config" => {
					"baud" => 9600
				},
				"state_vars" => {
					"name" => {
						"type" => "string",
						"state" => "Projector"
					},
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
		ds.state_vars[:name].should == {:type => :string}
		ds._id.should == "0a2392bb27551acf35cdd1ca621ec26b"
		ds._rev.should == "1654-ff63755fb7999e3d6fb97cc011575c38"
	end
end	
describe "handling requests from amqp" do
	it "should work for commands" do
		Thread.abort_on_exception = true
		class DeviceSubclass < DeviceTest
			command :power, :action => proc{|on| "power=#{on}"}
		end
		
		ds = DeviceSubclass.new
		ds.name = "Extron"
		
		json = '{
			"id": "FF00F317-108C-41BD-90CB-388F4419B9A1",
			"queue": "roomtrol:test:2",
			"type": "command",
			"method": "power",
			"args": [true]
		}'
		AMQP.start(:host => 'localhost') do
			ds.run
			amq = MQ.new
			amq.queue('roomtrol:dqueue:Extron').publish(json)
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
		class DeviceSubclass < DeviceTest
			state_var :name, :type => :string
		end
		
		#@redis.del("roomtrol:test:1")
		#redis.del("roomtrol:dqueue:Extron")
		
		ds = DeviceSubclass.new
		ds.name = "Extron"
		
		json = '{
			"id": "FF00F317-108C-41BD-90CB-388F4419B9A1",
			"queue": "roomtrol:test:1",
			"type": "state_get",
			"var": "name"
		}'
		AMQP.start(:host => 'localhost') do
			ds.run
			amq = MQ.new
			amq.queue('roomtrol:dqueue:Extron').publish(json)
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

end
