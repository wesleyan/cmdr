#require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/../lib/device.rb'
# Time to add your specs!
# http://rspec.info/
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
			state_var :name
		end
	end

	it "should create accessor methods for state_var" do
		class DeviceSubclass < Wescontrol::Device
			state_var :name
		end
		ds = DeviceSubclass.new
		ds.name = "name"
		ds.name.should == "name"
	end
	
	it "should inherit state_vars" do
		class DeviceSubclass < Wescontrol::Device
			state_var :name
		end
		class DeviceSubSubclass < DeviceSubclass
		end
		dss = DeviceSubSubclass.new
		dss.name = "name"
		dss.name.should == "name"
	end
	
	it "should not share state_var values between subclasses" do
		class DeviceSubclass < Wescontrol::Device
			state_var :name
		end
		class DeviceSubSubclass < DeviceSubclass
			state_var :another
		end
		ds = DeviceSubclass.new
		ds.name = "name"
		ds.name.should == "name"
		
		dss = DeviceSubSubclass.new
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
end
