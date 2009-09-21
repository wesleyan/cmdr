require 'rubygems'
require 'serialport'
require 'bitpack'

require '/usr/local/wescontrol/daemon/devices/Projector'

class NECProjector < Projector
	
	attr_reader :power, :cooling, :input, :video_mute, :has_signal, :picture_displaying,
		:projector_model, :projector_id, :projector_name, :lamp_hours, :percent_lamp_used, 
		:filter_hours, :projector_usage, :warming
	
	RGB1   = 1
	RGB2   = 2
	VIDEO  = 6
	SVIDEO = 11
	INPUT_HASH = {"RGB1" => 1, "RGB2" => 2, "VIDEO" => 6, "SVIDEO" => 11}
	
	MODEL_MAP = {[10, 4, 9]=>"NP300", [3, 0, 6]=>"VT80", [12, 0, 8]=>"NP1150/NP2150/NP3150", [11, 1, 0]=>"NP62", [10, 1, 9]=>"NP500", [2, 2, 3]=>"LT240K/LT260K", [12, 2, 9]=>"VT800", [4, 0, 3]=>"GT5000", [4, 1, 1]=>"GT2150", [2, 1, 3]=>"LT220", [2, 0, 6]=>"LT380", [1, 2, 3]=>"MT1075", [10, 3, 9]=>"NP400", [8, 0, 7]=>"NP4000/NP4001", [6, 0, 5]=>"WT610/WT615", [3, 0, 4]=>"VT770", [11, 0, 0]=>"NP41/61", [10, 0, 9]=>"NP600", [5, 0, 3]=>"HT1000", [2, 0, 5]=>"LT245/LT265", [1, 0, 6]=>"NP1000/NP2000", [12, 1, 9]=>"NP901W", [4, 1, 3]=>"GT6000", [4, 0, 1]=>"GT1150", [1, 0, 1]=>"MT1060/MT1065", [10, 0, 8]=>"VT700", [2, 1, 6]=>"LT280", [12, 1, 8]=>"NP3151W", [10, 2, 9]=>"NP500", [6, 0, 3]=>"WT600", [5, 0, 4]=>"HT1100", [3, 0, 7]=>"VT90", [2, 0, 3]=>"LT240/LT260", [12, 0, 9]=>"NP905", [1, 1, 3]=>"MT860"}

	def initialize(name, bus, config)
		puts "Initializing projector on port #{config['port']} with name #{name}"
		Thread.abort_on_exception = true
	
		super(config['port'], 9600, 8, 1, name, bus)

		#@frames stores an array of messages that are currently being sent, indexed by id2 (which seems to be unique for each command--honestly, I have no
		#clue how id1 and id2 are supposed to work, despite several hours of trying to figure out. For the input command (id2=3) any id1 in the format
		#xxx000xx seems to work, but for running_sense (id2=0x81) only id=2 produces the correct output.) This limits you to one message for each id2, but
		#that seems to be the only way this can work since id1 doesn't work like it seems like it ought to (i.e., as an index for error-correction)
		@frames = Array.new(2**8)
		@responses = Array.new(2**8)
		
		@buffer = []
		
		@commands = {
			#format is :name => [id1, id2, data, callback]
			:power=              => [2, proc {|on| on ? 0 : 1}, nil, nil],
			:video_mute=         => [2, proc {|on| on ? 0x10 : 0x11}, nil, nil],
			:input=              => [2, 3, proc {|source| [1, INPUT_HASH[source]].pack("cc")}, nil],
			:brightness=		 => [3, 0x10, proc {|brightness| [0, 0xFF, 0, brightness, 0].pack("ccccc")}, nil],
			:running_sense       => [0, 0x81, nil, proc {|frame|
				@power       = frame["data"][0] & 2**1 != 0
				was_cooling = @cooling
				@cooling     = frame["data"][0] & 2**5 != 0 && !@warming
				#projector is warming if it is doing power processing (bit 7) and not cooling
				#this is not supported on MT1065's, but is on NPs
				@warming     = (frame["data"][0] & 2**7 != 0) && !was_cooling
			}],
			:common_data_request => [0, 0xC0, nil, proc {|frame|
				data = frame["data"]
				@power = data[3] == 1
				@cooling = data[4] == 1 if !@warming
				#puts "DATA: #{data[6..7]}"
				case data[6..7]
					when [1, 1] then @input = "RGB1"
					when [2, 1] then @input = "RGB2"
					when [1, 2] then @input = "VIDEO"
					when [1, 3] then @input = "SVIDEO"
				end
				@video_mute = data[28] == 1
				@projector_model = MODEL_MAP[[data[0], data[69], data[70]]]
				@has_signal = data[84] != 1
				@picture_displaying = data[84] == 0
			}],
			:lamp_information => [3, 0x8A, nil, proc {|frame|
				data = frame["data"]
				#projector_name is a null-terminated string taking up at most bytes 0..48
				@projector_name = data[0..[48, data.index(0)].min].pack("c*")
				#they use a bizarre method of encoding for these, which is essentially bytes 82..85 
				#contatenated in hex in inverse order. Also, despite the name, values are in seconds.
				def get_hours(array)
					return (array.reverse.collect{|hex| hex.to_s(16)}.join.to_i(16)/3600.0).round()
				end
				@lamp_hours      = get_hours(data[82..85])
				@filter_hours    = get_hours(data[86..89])
				@projector_usage = get_hours(data[94..97])
			}],
			:lamp_remaining => [3, 0x94, nil, proc {|frame|
				@percent_lamp_used = 100-frame['data'][4] #percent remaining is what's returned
			}]
		}

		Thread.new{ read() }
		Thread.new{
			while true do
				self.running_sense
				sleep(0.3)
			end
		}

		Thread.new{
			while true do
				self.common_data_request
				sleep(1)
			end
		}
		Thread.new{
			while true do
				self.lamp_information
				self.lamp_remaining
				sleep(10)
			end
		}

		check_status()
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
	
	def send_command(id1, id2, data = nil, callback = nil, projector_id = 0, model_code = 0)
		#puts "id1 = #{id1}, id2 = #{id2}, data = #{data}"
		message = package_message(id1, id2, data, projector_id, model_code)
		#puts "Message = #{message.inspect}"
		self.send_string(message)
		@frames[id2] = callback
		@responses[id2] = nil
		return wait_for_response(id2)
	end

    def package_message(id1, id2, data, projector_id, model_code)
        # create a new BitPack object to pack the message into
        bp = BitPack.new

        bp.append_bits(id1, 8)
        bp.append_bits(id2, 8)
        bp.append_bits(projector_id, 8)
        bp.append_bits(model_code, 4)
        if data
            bp.append_bits(data.size, 12)
            bp.append_bytes(data)
        else
            bp.append_bits(0, 12)
        end
        
        #now append the checksum, which is the last 8 bits of the sum of all the other stuff
        sum = 0
        bp.to_bytes.each_byte{|byte| sum += byte}
        bp.append_bits(sum & 255, 8) #mask by 255 to get just the last 8 bits
        
        #puts bp.to_bin.scan(/.{1,8}/m).collect{|a| a.to_i(2).to_s(16)}.join(" ")
        return bp.to_bytes
    end
	
	def interpret_message(frame)
		bp = BitPack.new

		bp.append_bytes(frame.pack("c*"))

		cm = {}
		cm["id1"] = bp.read_bits(8)
		cm["id2"] = bp.read_bits(8)
		cm["projector_id"] = bp.read_bits(8)
		cm["model_code"] = bp.read_bits(4)
		cm["data_size"] = bp.read_bits(12)

		cm["data"] = frame[5..-2] if cm["data_size"] > 0

		cm["checksum"] = bp.read_bits(8)
		
		#Test whether the bit 8 is set or not. If it is, the response is acknowledged
		#printf("id1: %08b\n", cm["id1"])
		#cm["ack"] = cm["id1"] & 2**7 != 0
		cm["ack"] = cm["id1"] >> 4 == 2

		#puts "ACK" if cm["id1"] >> 4 == 0xA
		#puts "NACK" if cm["id1"] >> 4 == 0x2
		
		return cm
	end
	
	def read
		while true do
			@buffer << @serial_port.getc
			@buffer[0..-6].each_index{|i|
				#this fun line uses bit-level operations to get the 12 bits that are the size of the data
				#data_size = ((@buffer[i + 4] & 0b1111) << 8) + @buffer[i + 5]
				data_size = @buffer[i + 4]

				#puts "Data size = #{data_size}"
				#we make sure that, assuming that a frame started on index i of the buffer, we have all of the
				#bytes that make up the frame
				if @buffer.size && @buffer.size - i >= 5 + data_size
					#we add up the bytes of the supposed frame, and see if it matches the checksum
					#if it does, it's probably a frame and we will treat it as such
					bytes = @buffer[i..(i + 4 + data_size + 1)]
					
					if bytes[-1] != 0 && bytes[-1] == bytes[0..-2].inject{|sum, byte| sum += byte} & 255
						#printf("%08b " * bytes.size + "\n", *bytes)
						frame = interpret_message(bytes)
						if frame['id2'] && frame['id1'] != 0
							if frame["ack"]
								begin
									@frames[frame['id2']].call(frame) if @frames[frame['id2']]
								rescue
									puts "Error in NECProjector: #{$!}"
								end
								@responses[frame['id2']] = ""
							else
								@responses[frame['id2']] = interpret_error(frame)
							end
						end
						@buffer = []
						break
					end
					
				end
			}
		end
	end
	
	def interpret_error(frame)
		error_codes = {0 => "Not supported", 1 => "Parameter error", 2 => "Operation mode error", 
			3 => "Gain-related error", 4 => "Logo transfer error"}
		if frame['data'] && frame['data'][0]
			puts "#{frame['id2'].to_s(16)}: The response was not acknowledged: #{error_codes[frame['data'][0]]}: #{frame['data'][1]}"
			return "The response was not acknowledged: #{error_codes[frame['data'][0]]}: #{frame['data'][1]}"
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
