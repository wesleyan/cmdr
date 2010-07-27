#---
#{
#	"name": "IREmitter",
#	"depends_on": "Device",
#	"description": "Controls any IR device with a LIRC configuration",
#	"author": "Micah Wylde",
#	"email": "mwylde@wesleyan.edu"
#}
#---

require 'socket'
#TODO: Rewrite using non-blocking socket library

class IREmitter < Wescontrol::Device

	command :pulse_command, :action => proc {|button|
		_command = "send_once #{@remote} #{button}"
		@commands[_command] = nil
		begin
			@socket.write(_command + "\n")
		rescue
			begin
				@socket = UNIXSocket.open(@port)
				@socket.write(_command + "\n")
			rescue
				next "Failed to communicate with IR emitter"
			end
		end

		20.times {|t|
			break if @commands[_command]
			sleep(0.1)
		}
		next @commands[_command] if @commands[_command]
		next "Failed to communicate with IR emitter"
	}

	def initialize(name, options)
		Thread.abort_on_exception = true
		options = options.symbolize_keys
		DaemonKit.logger.info "Initializing IR Emitter #{options[:name]} with remote #{options[:remote]}"
		super(name, options)
		@commands = {}
		@remote = options[:remote]
		throw "No remote specified" unless @remote
		#@port = options[:port]
		@port = "/var/run/lirc/lircd" unless @port
		begin
			@socket = UNIXSocket.open(@port)
		rescue
			throw "Failed to create socket: #{$!}"
		end
	end
	
	def run
		read()
		super
	end
	
	def read
		Thread.start do
			buffer = []
			line = ""
			while true do
				if @socket && !@socket.closed?
					byte = @socket.recvfrom(1)[0]
					unless byte == "\n"
						line += byte
						next
					end
					DaemonKit.logger.debug "READING: #{line}"
					buffer = [] if line.strip == "BEGIN"
					buffer.push(line)
					if line.strip == "END"
						DaemonKit.logger.debug "#{buffer[1]}: #{buffer[2]}"
						@commands[buffer[1]] = buffer[2]
					end
					line = ""
				else
					sleep(0.1)
				end
			end
		end
	end
	
end
