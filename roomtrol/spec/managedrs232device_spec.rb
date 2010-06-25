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
	it "should create action methods that add the message to the send queue" do
		class MR232DeviceSubclass < MR232Device
			attr_accessor :string
			state_var :input, 
				:type => :options, 
				:display_order => 1, 
				:options => ("1".."6").to_a,
				:response => :channel,
				:action => proc{|input|
					"#{input}!\r\n"
				}
			def send_string string
				@string = string
			end
		end
		ds = MR232DeviceSubclass.new(:name => "Extron", :port => "/dev/null")
		ds.set_input(4)
		ds.string.should == "4!\r\n"
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
		$proc = proc{|r| self.input = r.strip[-1].to_i.to_s}
		class MR232DeviceSubclass < MR232Device
			responses do
				match :channel,  /Chn\d/, $proc
			end
		end
		MR232DeviceSubclass.instance_variable_get(:@matchers)[0].should == [:channel, /Chn\d/, $proc]
	end
	it "should allow setting multiple matches" do
		$proc = proc{|r| self.input = r.strip[-1].to_i.to_s}
		class MR232DeviceSubclass < MR232Device
			responses do
				match :channel,  /Chn\d/, $proc
				match :volume, /Vol\d/, $proc
			end
		end
		MR232DeviceSubclass.instance_variable_get(:@matchers).should == [
			[:channel, /Chn\d/, $proc],
			[:volume, /Vol\d/, $proc],
		]
	end
	it "should properly match regexps" do
		class MR232DeviceSubclass < MR232Device
			state_var :input, 
				:type => 'option', 
				:display_order => 1, 
				:options => ("1".."6").to_a,
				:response => :channel,
				:action => proc{|input|
					"#{input}!\r\n"
				}
			state_var :volume,
				:type => 'percentage',
				:display_order => 2,
				:response => :volume,
				:action => proc{|volume|
					"#{(volume*100).to_i}V\r\n"
				}
			responses do
				match :channel,  /Chn\d/, proc{|r| self.input = r.strip[-1].to_i}
				match :volume,   /Vol\d+/, proc{|r| self.volume = r.strip[3..-1].to_i/100.0}
			end
		end
		ds = MR232DeviceSubclass.new(:name => "Extron", :port => '/dev/null')
		ds.read "Chn4\r\n"
		ds.read "Vol12\r\n"
		ds.input.should == 4
		ds.volume.should == 0.12
	end
end