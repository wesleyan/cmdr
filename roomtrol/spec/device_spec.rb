#require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/../lib/device.rb'
# Time to add your specs!
# http://rspec.info/

class DaemonKit
	def self.logger
		return Logger
	end
	class Logger
		def self.debug x
			puts "Debug: #{x}"
		end
		def self.log x
			puts "Log: #{x}"
		end
		def self.error x
			puts "Error: #{x}"
		end
	end
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
end

describe "deal with state_vars properly" do
	it "should respond to state_var" do
		class DeviceSubclass < Wescontrol::Device
			state_var :name, :type => :string
		end
	end
	
	it "should require a :type field" do
		proc {
			class DeviceSubclass < Wescontrol::Device
				state_var :name
			end
		}.should raise_error
		
		proc {
			class DeviceSubclass < Wescontrol::Device
				state_var :name, :someting => :else
			end
		}.should raise_error
	end

	it "should create accessor methods for state_var" do
		class DeviceSubclass < Wescontrol::Device
			state_var :name, :type => :string
		end
		ds = DeviceSubclass.new
		ds.name = "name"
		ds.name.should == "name"
	end
	
	it "should inherit state_vars" do
		class DeviceSubclass < Wescontrol::Device
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
		class DeviceSubclass < Wescontrol::Device
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
		class DeviceSubclass < Wescontrol::Device
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
		class DeviceSubclass < Wescontrol::Device
			state_var :power, :type => :string, :action => proc {|x| "hello #{x}"}
		end
		ds = DeviceSubclass.new
		ds.set_power("micah").should == "hello micah"
	end
end

describe "do virtual vars" do
	it "should allow creation of virtual vars" do
		class DeviceSubclass < Wescontrol::Device
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
	it "should recalculate virtual vars" do
		class DeviceSubclass < Wescontrol::Device
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
		ds = DeviceSubclass.new
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
		class DeviceSubSubclass < DeviceSubclass
			virtual_var :full_name_inverse, 
				:type => :string, 
				:depends_on => [:first, :last], 
				:transformation => proc {
					"#{last} #{first}"
				}
		end
		ds = DeviceSubclass.new
		ds.first = "Micah"
		ds.last = "Wylde"
		ds.full_name.should == "Micah Wylde"
		dss = DeviceSubSubclass.new
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
		ds = DeviceSubclass.new
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
end
