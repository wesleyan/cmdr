require 'socket'

class IREmitter < Wescontrol::Device

	command :pulse_command, :action => proc {
		command = "SEND_ONCE #{@remote} #{button}"
		@commands[command] = nil
		begin
			@socket.write("#{command}\n", 0)
		rescue
			begin
				@socket = UNIXSocket.open("/dev/lircd")
				@socket.send("#{command}\n", 0)
			rescue
				return "Failed to communicate with IR emitter"
			end
		end

		20.times {|t|
			return @commands[command] if @commands[command]
			sleep(0.1)
		}
		return ["Failed to communicate with IR emitter"]
	}

	def initialize(options)
		puts "Initializing IR Emitter: #{options[:name]}"
		options = options.symbolize_keys
		super(options)
		begin
			@socket = UNIXSocket.open("/dev/lircd")
		rescue
		end
		@commands = {}
		@remote = options[:remote]
		read()
	end
	
	def read
		Thread.start do
			buffer = []
			line = ""
			while true do
				if @socket && !@socket.closed?
					byte = @socket.recvfrom(1)[0]
					unless byte == "\n"[0]
						line += byte
						next
					end
					puts "READING: #{line}"
					buffer = [] if line.strip == "BEGIN"
					buffer.push(line)
					if line.strip == "END"
						puts "#{buffer[1]}: #{buffer[2]}"
						@commands[buffer[1]] = buffer[2]
					end
				else
					sleep(0.1)
				end
			end
		end
	end
	
end
