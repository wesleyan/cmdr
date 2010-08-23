require_relative 'spec_helper.rb'
require_relative '../lib/roomtrol/device.rb'
require_relative '../lib/roomtrol/wescontrol_http'
# Time to add your specs!
# http://rspec.info/



describe "HTTP API" do
  
	it "should respond to a GET request" do
		class DeviceSubclass < Wescontrol::Device
			state_var :volume, :type => :percentage
		end
		
		ds = DeviceSubclass.new("extron")
		ds.volume = 0.5
		Wescontrol::WescontrolHTTP.instance_variable_set(:@devices, ["extron"])
		EventMachine::run {
			ds.run
			EventMachine::start_server "0.0.0.0", 9812, Wescontrol::WescontrolHTTP
			http = EventMachine::Protocols::HttpClient.request(
				:host => "0.0.0.0",
				:port => 9812,
				:request => "/devices/extron/volume"
			)
			http.callback {|response|
				@called = true
			 	JSON.parse(response[:content]).should == {"result" => 0.5}
				AMQP.stop {
					EM.stop
				}
			}		 
		}
		@called.should == true
	end
	it "should respond to a setting state_vars" do
		class DeviceSubclass < Wescontrol::Device
			state_var :volume, :type => :percentage, :action => proc {|v|
				self.volume = v
			}
		end
		
		ds = DeviceSubclass.new("extron")
		ds.volume = 0.5
		Wescontrol::WescontrolHTTP.instance_variable_set(:@devices, ["extron"])
		EventMachine::run {
			ds.run
			EventMachine::start_server "0.0.0.0", 9812, Wescontrol::WescontrolHTTP
			http = EventMachine::Protocols::HttpClient.request(
				:host => "0.0.0.0",
				:port => 9812,
				:request => "/devices/extron/volume",
				:content => {'value' => 1.0}.to_json,
				:verb => "POST"
			)
			http.callback {|response|
				@called = true
			 	JSON.parse(response[:content]).should == {"result" => 1.0}
				ds.volume.should == 1.0
				AMQP.stop {
					EM.stop
				}
			}		 
		}
		@called.should == true
	end
	it "should respond to a command" do
		class DeviceSubclass < Wescontrol::Device
			command :play, :action => proc {|arg|
				arg.upcase
			}
		end
		
		ds = DeviceSubclass.new("extron")
		Wescontrol::WescontrolHTTP.instance_variable_set(:@devices, ["extron"])
		EventMachine::run {
			ds.run
			EventMachine::start_server "0.0.0.0", 9812, Wescontrol::WescontrolHTTP
			http = EventMachine::Protocols::HttpClient.request(
				:host => "0.0.0.0",
				:port => 9812,
				:request => "/devices/extron/play",
				:content => {'args' => ["hello"]}.to_json,
				:verb => "POST"
			)
			http.callback {|response|
				@called = true
			 	JSON.parse(response[:content]).should == {"result" => "HELLO"}
				AMQP.stop {
					EM.stop
				}
			}		 
		}
		@called.should == true
	end
	
	it "should send appropriate error messages" do
		Wescontrol::WescontrolHTTP.instance_variable_set(:@devices, ["extron"])
		@called = 0
		@tests = [
			["/hello", {"error" => "resource_not_found"}, 404],
			["/devices/extron", {"error" => "must_provide_target"}, 400],
			["/devices/hello/power", {"error" => "device_not_found"}, 404]
		]
		EventMachine::run {
			@callback = proc{|response, content, status|
				@called += 1
				JSON.parse(response.content).should == content
				response.status.should == status
				if @called == @tests.size
					AMQP.stop {
						EM.stop
					}
				end
			}
			
			EventMachine::start_server "0.0.0.0", 9812, Wescontrol::WescontrolHTTP
			@tests.each{|test|
				conn = EM::Protocols::HttpClient2.connect '0.0.0.0', 9812
				req = conn.get(test[0])
				req.callback{|response| @callback.call(response, test[1], test[2])}
			}
		}
		@called.should == @tests.size
	end
	
end
