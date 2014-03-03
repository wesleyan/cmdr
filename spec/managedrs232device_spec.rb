require_relative 'spec_helper.rb'
require_relative '../lib/cmdr/device.rb'
require_relative '../lib/cmdr/rs232device.rb'

RSpec.configure do |config|
	#For some reason in Ruby 1.9.2 class definition constants leak between tests, causing errors
	config.before(:each) {
		Object.send(:remove_const, :MR232DeviceSubclass) if Object.constants.include? :MR232DeviceSubclass
	}
end

describe "managed_state_var enhancements" do
	it "shouldn't break managed_state_vars" do
		class MR232DeviceSubclass1 < Cmdr::RS232Device
			managed_state_var :input, 
				:type => :options, 
				:display_order => 1, 
				:options => ("1".."6").to_a,
				:response => :channel,
				:action => proc{|input|
					"#{input}!\r\n"
				}
		end
		MR232DeviceSubclass1.state_vars[:input][:type] == :option
	end
	it "should create action methods that add the message to the send queue" do
		class MR232DeviceSubclass2 < Cmdr::RS232Device
			attr_accessor :_send_queue
			managed_state_var :input, 
				:type => :options, 
				:display_order => 1, 
				:options => ("1".."6").to_a,
				:response => :channel,
				:action => proc{|input|
					"#{input}!\r\n"
				}
		end
		ds = MR232DeviceSubclass2.new("Extron", :port => "/dev/null")
		ds.set_input(4)
		ds._send_queue[0][0].should == "4!\r\n"
	end
end

describe "do responses" do
	it "should respond to responses" do
		class MR232DeviceSubclass3 < Cmdr::RS232Device
			responses do
			end
		end
	end

	it "should allow setting responses with match" do
		$proc = proc{|m| self.input = m[1]}
		class MR232DeviceSubclass4 < Cmdr::RS232Device
			responses do
				match :channel,  /Chn(\d)/, $proc
			end
		end
		MR232DeviceSubclass4.instance_variable_get(:@_matchers)[0].should == [:channel, /Chn(\d)/, $proc]
	end
	it "should allow setting multiple matches" do
		$proc = proc{|m| self.input = m[1]}
		class MR232DeviceSubclass5 < Cmdr::RS232Device
			responses do
				match :channel,  /Chn(\d)/, $proc
				match :volume, /Vol(\d)/, $proc
			end
		end
		MR232DeviceSubclass5.instance_variable_get(:@_matchers).should == [
			[:channel, /Chn(\d)/, $proc],
			[:volume, /Vol(\d)/, $proc],
		]
	end
	it "should properly match regexps, strings and procs" do
		class MR232DeviceSubclass6 < Cmdr::RS232Device
			managed_state_var :input, 
				:type => 'option', 
				:display_order => 1, 
				:options => ("1".."6").to_a,
				:response => :channel,
				:action => proc{|input|
					"#{input}!\r\n"
				}
			managed_state_var :volume,
				:type => 'percentage',
				:display_order => 2,
				:response => :volume,
				:action => proc{|volume|
					"#{(volume*100).to_i}V\r\n"
				}
			responses do
				match :channel,  /Chn(\d)/, proc{|m| self.input = m[1].to_i}
				match :volume,   /Vol(\d+)/, proc{|m| self.volume = m[1].to_i/100.0}
				match :something, "hello", proc{ self.volume = 22 }
				match :else, proc {|x| x.to_i != 0}, proc{|m| self.volume = m.to_i}
			end
		end
		ds = MR232DeviceSubclass6.new("Extron", :port => '/dev/null')
		ds.read "Chn4\r\n"
		ds.read "Vol12\r\n"
		ds.input.should == 4
		ds.volume.should == 0.12
		ds.read "hello\r\n"
		ds.volume.should == 22
		ds.read "512\r\n"
		ds.volume.should == 512
	end

  it "should properly match with messages defined by a regex message_end" do
		class MR232DeviceSubclass7a < Cmdr::RS232Device
			configure do
				message_end(/\r\n|\n\r/)
			end
			managed_state_var :input, 
      :type => 'option', 
      :display_order => 1, 
      :options => ("1".."6").to_a,
      :response => :channel,
      :action => proc{|input|
        "#{input}!\r\n"
      }
			managed_state_var :volume,
      :type => 'percentage',
      :display_order => 2,
      :response => :volume,
      :action => proc{|volume|
        "#{(volume*100).to_i}V\r\n"
      }
			responses do
				match :channel,  /Chn(\d)/, proc{|m| self.input = m[1].to_i}
				match :volume,   /Vol(\d+)/, proc{|m| self.volume = m[1].to_i/100.0}
				match :something, "hello", proc{ self.volume = 22 }
				match :else, proc {|x| x.to_i != 0}, proc{|m| self.volume = m.to_i}
			end
		end
		ds = MR232DeviceSubclass7a.new("Extron", :port => '/dev/null')
    ds.read "asdf3234asdf\r\n"
		ds.read "Chn4\r\n"
		ds.read "Vol12\n\r"
		ds.input.should == 4
		ds.volume.should == 0.12
		ds.read "hello\n\r"
		ds.volume.should == 22
		ds.read "512\r\n"
		ds.volume.should == 512
		ds.read "23423\n\rVol44\r\nChn3\r\n"
		ds.volume.should == 0.44
		ds.input.should == 3
	end

  
	it "should properly match with messages defined by message_format" do
		class MR232DeviceSubclass7 < Cmdr::RS232Device
			configure do
				message_format(/#(.+?)#/)
			end
			managed_state_var :input, 
				:type => 'option', 
				:display_order => 1, 
				:options => ("1".."6").to_a,
				:response => :channel,
				:action => proc{|input|
					"#{input}!\r\n"
				}
			managed_state_var :volume,
				:type => 'percentage',
				:display_order => 2,
				:response => :volume,
				:action => proc{|volume|
					"#{(volume*100).to_i}V\r\n"
				}
			responses do
				match :channel,  /Chn(\d)/, proc{|m| self.input = m[1].to_i}
				match :volume,   /Vol(\d+)/, proc{|m| self.volume = m[1].to_i/100.0}
				match :something, "hello", proc{ self.volume = 22 }
				match :else, proc {|x| x.to_i != 0}, proc{|m| self.volume = m.to_i}
			end
		end
		ds = MR232DeviceSubclass7.new("Extron", :port => '/dev/null')
		ds.read "#Chn4#"
		ds.read "#Vol12#"
		ds.input.should == 4
		ds.volume.should == 0.12
		ds.read "#hello#"
		ds.volume.should == 22
		ds.read "#512#"
		ds.volume.should == 512
		ds.read "#23423##Vol44##Chn3#"
		ds.volume.should == 0.44
		ds.input.should == 3
	end
	
end

describe "do requests" do
	it "should properly send requests" do
		puts "Doing this test"
		class MR232DeviceSubclass8 < Cmdr::RS232Device
			attr_reader :string_array
			def initialize(name, options)
				super(name, options)
				@string_array = []
			end
			
			configure do
				message_timeout 0.05
			end

			requests do
				send :input, "I\r\n", 1.5
				send :volume, "V\r\n", 0.5
				send :mute, "Z\r\n", 1.0
			end
			
			def send_string string
				@string_array << string
			end
		end
		ds = MR232DeviceSubclass8.new("Extron", :port => "/dev/null")
		EM::run {
			EM::add_periodic_timer(1) {
				AMQP.stop do
					EM.stop
				end
			}
			ds.run
		}
		ds.string_array[0..5].should == ["I\r\n", "V\r\n", "Z\r\n", "I\r\n", "Z\r\n", "I\r\n"]
	end
end

describe "sending messages" do
	it "should respond to AMQP messages appropriately" do
		puts "doing this test"
		class MR232DeviceSubclass9 < Cmdr::RS232Device
			attr_reader :string_array
			
			configure do
				message_timeout 0.1
			end
			
			def initialize(name, options)
				super(name, options)
				@string_array = []
				@power = true
			end
			
			managed_state_var :power, 
				:type => :boolean,
				:action => proc{|p| "power=#{p}\r\n"}
				
			def send_string string
				@string_array << string
			end
		end
		
		ds = MR232DeviceSubclass9.new('ExtronTestDevice', :port => '/dev/null')
		json = '{
			"id": "FF00F317-108C-41BD-90CB-388F4419B9A1",
			"queue": "cmdr:test:3",
			"type": "state_set",
			"var": "power",
			"value": false
		}'
	end
end
