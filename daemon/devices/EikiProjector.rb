require 'rubygems'
require 'serialport'
require 'bitpack'

require 'devices/Projector'

class EikiProjector < Projector
	
	attr_reader :power, :cooling, :input, :video_mute
	
	RGB1   = 1
	RGB2   = 2
	VIDEO  = 6
	SVIDEO = 11
	INPUT_HASH = {"RGB1" => 1, "RGB2" => 2, "VIDEO" => 6, "SVIDEO" => 11}
	

	def initialize(name, port, bus)
		puts "Initializing projector on port #{port} with name #{name}"
		Thread.abort_on_exception = true
	
		super(port, 19200, 8, 1, name, bus)

		@frames = Array.new(2**8)
		@responses = Array.new(2**8)
		
		@buffer = []
		
		@commands = {
			#format is :name => [id1, id2, data, callback]
			:power=              => [proc {|on| on ? "00" : "01"}],
			:video_mute=         => [proc {|on| on ? "0D" : "0E"}]
			#:input=              => [2, 3, proc {|source| [1, INPUT_HASH[source]].pack("cc")}, nil]
		}

		Thread.new{ read() }


		#check_status()
	end

	
	def method_missing(method_name, *args)
		if @commands[method_name]
			command = @commands[method_name][0..-2].collect{|element| element.class == Proc ? element.call(*args) : element}
			command << @commands[method_name][-1]
			return send_command(*command)
		else
			super.method_missing(method_name, *args)
		end
	end
	
	def wait_for_response(id2)
		count = 0
		while(!@responses[id2])
			#wait 1 seconds for a response before giving up
			return "No response from projector" if count > 10*3
			count += 1
			sleep(0.1)
		end
		#puts "Response is #{@responses[id2]}"
		response = @responses[id2]
		@responses[id2] = nil
		return response
	end

	private
	
	def send_command(id)
		#puts "id1 = #{id1}, id2 = #{id2}, data = #{data}"
		#puts "Message = #{message.inspect}"
		self.send_string("CR0")
		return "ok"
	end

	
	def read
		while true do
			@buffer << @serial_port.getc
			@buffer[0..-6].each_index{|i|
				puts "RECEIVED BIT: #{i}"
			}
		end
	end
	

	
	
	def check_status
		Thread.new{
			class_vars = [:power, :cooling, :input, :video_mute, :has_signal, :picture_displaying,
						:projector_model, :projector_name, :lamp_hours, :percent_lamp_used, 
						:filter_hours, :projector_usage, :warming]
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
end

def projector_test
	p = NECProjector.new(0)

	p.power = true
	sleep(10)
	p.input = NECProjector::VIDEO
	sleep(20)
	puts "About to turn video mute on"
	p.video_mute = true
	sleep(10)
	puts "About to turn video mute off"
	p.video_mute = false
	sleep(30)
	puts "Power off"
	p.power = false
	sleep(100)
	sleep(1000)
	sources = [NECProjector::SVIDEO, NECProjector::VIDEO, NECProjector::RGB1, NECProjector::RGB2]
end
