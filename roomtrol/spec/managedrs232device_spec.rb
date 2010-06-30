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
			attr_accessor :_send_queue
			state_var :input, 
				:type => :options, 
				:display_order => 1, 
				:options => ("1".."6").to_a,
				:response => :channel,
				:action => proc{|input|
					"#{input}!\r\n"
				}
		end
		ds = MR232DeviceSubclass.new(:name => "Extron", :port => "/dev/null")
		ds.set_input(4)
		ds._send_queue[0][0].should == "4!\r\n"
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
		MR232DeviceSubclass.instance_variable_get(:@_matchers)[0].should == [:channel, /Chn\d/, $proc]
	end
	it "should allow setting multiple matches" do
		$proc = proc{|r| self.input = r.strip[-1].to_i.to_s}
		class MR232DeviceSubclass < MR232Device
			responses do
				match :channel,  /Chn\d/, $proc
				match :volume, /Vol\d/, $proc
			end
		end
		MR232DeviceSubclass.instance_variable_get(:@_matchers).should == [
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

describe "do requests" do
	it "should properly send requests" do
		class MR232DeviceSubclass < MR232Device
			attr_reader :string_array
			def initialize(options)
				super(options)
				@string_array = []
			end
			configure do
				baud        9600
				message_end "\r"
			end

			requests do
				send :input, "I\r\n", 0.5
				send :volume, "V\r\n", 1
				send :mute, "Z\r\n", 0.5
			end
			
			def send_string string
				@string_array << string
			end
		end
		ds = MR232DeviceSubclass.new(:name => "Extron", :port => "/dev/null")
		EM::run {
			EM::add_periodic_timer(3) {
				AMQP.stop do
					EM.stop
				end
			}
			ds.run
		}
		ds.string_array[0..3].sort.should == ["I\r\n", "V\r\n", "V\r\n", "Z\r\n"]
	end
end

describe "sending messages" do
	it "should respond to AMQP messages appropriately" do
		class MR232DeviceSubclass < MR232Device
			attr_reader :string_array
			def initialize(options)
				super(options)
				@string_array = []
				@power = true
			end
			state_var :power, 
				:type => :boolean,
				:action => proc{|p| "power=#{p}\r\n"}
			def send_string string
				@string_array << string
			end
		end
		
		ds = MR232DeviceSubclass.new(:name => 'Extron', :port => '/dev/null')
		json = '{
			"id": "FF00F317-108C-41BD-90CB-388F4419B9A1",
			"queue": "roomtrol:test:3",
			"type": "state_set",
			"var": "power",
			"value": false
		}'
		AMQP.start(:host => '127.0.0.1') do
			ds.run
			amq = MQ.new
			amq.queue('roomtrol:dqueue:Extron').publish(json)
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
			"error" => nil
		}
		ds.string_array.should == ["power=false\r\n"]
	end
end