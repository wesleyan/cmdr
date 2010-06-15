require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/../lib/device.rb'
require File.dirname(__FILE__) + '/../lib/rs232device.rb'
require File.dirname(__FILE__) + '/../lib/managedrs232device.rb'
# Time to add your specs!
# http://rspec.info/

Spec::Runner.configure do |config|

	config.before(:each) {
		#this creates a mock save method so that nothing actually gets
		#saved to the database. There's probably a better way to do this,
		#involving mocking frameworks or a testing db.
		class MR232Device < Wescontrol::ManagedRS232Device
			def save
			end
		end
	}
end
describe "state_var enhancements" do	
	it "shouldn't break state_vars" do
		class MR232DeviceSubclass < MR232Device
			state_var :input, 
				:type => :options, 
				:display_order => 1, 
				:options => ("1".."6").to_a,
				:response => :channel,
				:action => proc{|input|
					"#{input}!\r\n"
				}
		end
		MR232DeviceSubclass.state_vars[:input][:type] == :option
	end
	
end

describe "do responses" do
	it "should respond to responses" do
		class MR232DeviceSubclass < MR232Device
			responses do
			end
		end
	end

	it "should allow setting responses with match" do
		class DeviceSubclass < DeviceTest
			responses do
				match :channel,  /Chn\d/, proc{|r| self.input = r.strip[-1].to_i.to_s}
			end
		end
	end
end