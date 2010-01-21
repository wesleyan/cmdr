require 'socket'

class IREmitter < Wescontrol::Device

	def initialize(options)
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
