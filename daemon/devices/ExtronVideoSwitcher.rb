require '/usr/local/wescontrol/daemon/devices/VideoSwitcher'

class ExtronVideoSwitcher < VideoSwitcher
	attr_reader :input, :volume, :mute, :model, :firmware_version, :part_number, :clipping

	def initialize(name, bus, config)
		puts "Initializing Extron on port #{config['port']} with name #{name}"
		Thread.abort_on_exception = true

		@commands = {
			#format is :name => [command, response_detector, callback]
			#The response_detector is a block that, when passed the response string, returns true if
			#the response was for that command
			:input=			=> [proc {|input| "#{input}!"}, proc {|r| r[0..2] == "Chn"}, proc {|r| @input = r[-1..-1].to_i}],
			:volume=		=> [proc {|volume| "#{(volume*100).to_i}V"}, proc {|r| r[0..2] == "Vol"}, proc {|r| @volume = r[3..-1].to_i/100.0}],
			:mute=			=> [proc {|on| on ? "1Z" : "0Z"}, proc {|r| r[0..2] == "Amt"}, proc {|r| @audio_mute = r[-1..-1] == "1"}],
			:get_status		=> ["I", proc {|r| r.scan(/Vid\d+ Aud\d+ Clp\d/).size > 0}, proc {|r|
				input = r.scan(/Vid\d+/).join("")[3..-1].to_i
				@input = input if input > 0
				@clipping = r.scan(/Clp\d+/).join("")[3..-1] == "1"
			}],
			:get_volume		=> ["V", nil, nil], #the response code for setting volume will handle these messages as well
			:get_audio_mute	=> ["Z", nil, nil] #same with this
		}

		@responses = {}
		@errors = {
			"E01" => "Invalid input channel number",
			"E10" => "Invalid command",
			"E13" => "Invalid value",
			"E14" => "Invalid for this configuration"
		}
		super(config['port'], 9600, 8, 1, name, bus)
		
		Thread.new{ read() }
		Thread.new{
			while true do
				self.get_status
				sleep(0.5)
			end
		}
		Thread.new {
			sleep(0.1) #these initial sleeps are to stagger the commands
			while true do
				self.get_volume
				sleep(0.5)
			end
		}
		Thread.new {
			sleep(0.2)
			while true do
				self.get_audio_mute
				sleep(0.5)
			end
		}
		check_status()
	end
	
	def send_command(name, arguments)
		if @commands[name]
			begin
				if @commands[name][0].class == Proc
					self.send_string(@commands[name][0].call(*arguments))
				elsif @commands[name][0].class == String
					self.send_string(@commands[name][0])
				end
				@responses[name] = nil
			rescue
				puts "Failed to send command #{name}: #{$!}"
			end
		else
			puts "No command '#{name}'"
		end
	end
	
	def method_missing(method_name, *args)
		if @commands[method_name]
			return send_command(method_name, args)
		else
			super.method_missing(method_name, *args)
		end
	end
	
	def wait_for_response(name)
		count = 0
		while(!@responses[name])
			#wait 1 seconds for a response before giving up
			return "No response from extron" if count > 10*3
			count += 1
			sleep(0.1)
		end
		#puts "Response is #{@responses[id2]}"
		response = @responses[name]
		@responses[name] = nil
		return response
	end
	
	def read
		while true do
			response = @serial_port.readline.strip
			if @errors[response]
				puts "Extron Error: #{response}"
			else
				command = nil
				@commands.each{|key, value|
					command = value if value[1] && value[1].call(response)
				}
				if command
					begin
						@responses[command[0]] = command[2].call(response)
					rescue
						puts "Error in ExtronVideoSwitcher: #{$!}"
					end
				end
			end

		end
	end
	def check_status
		Thread.new{
			class_vars = [:input, :volume, :mute, :model, :firmware_version, :part_number, :clipping]
			size = class_vars.collect{|var| var.to_s.size}.max
			old_values = {}
			while true do
				class_vars.each{|var|
					if old_values[var] != self.send(var)
						printf("%-#{size}s = %s\n", var, self.send(var).to_s)
						self.send("#{var.to_s}_changed".to_sym, self.send(var)) if self.respond_to?("#{var.to_s}_changed".to_sym)
						old_values[var] = self.send(var)
					end
				}
				sleep(0.1)
			end
		}
	end
	def self.test
		return self.new("extron", "/dev/ttyUSB1", nil)
	end
end
