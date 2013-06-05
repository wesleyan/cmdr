#---
#{
#	"name": "HitachiSwitcher",
#	"depends_on": "VideoSwitcher",
#	"description": "Controls Hitachi video switcher",
#	"author": "Sam Giagtzoglou",
#	"email": "sgiagtzoglou@wesleyan.edu"
#}
#---
#
#The switcher uses hex commands, and it has issues with concurrency: it can't handle more than one open socket at a time, 
#and it loves to stop talking and disconnect for almost no reason. So, instead of using managed_state_vars, state_vars
#are used to allow the driver code to handle all of the talking to the switcher. Sleep commands are used for rate limiting; 
#if the switcher is pounded with too many requests it will give up quickly

require "socket"
class HitachiSwitcher < Wescontrol::Device
	configure do
		DaemonKit.logger.info "@Initializing HitachiSwitcher at URI #{uri} with name #{name}"
	end

	state_var :video, :type => :option, :editable => :true, :options => ("1".."6").to_a, :action => proc{|input|
	    	if self.video != input #If input is not the input the switcher is already on
	    		DaemonKit.logger.info("Changing switcher input from #{self.video} to #{input}")
	    		@inputReq = input
	    		@inputChanging = true
	    	end
	    }

	state_var :volume, :type => :percentage, :editable => :true, :action => proc{|volume|
			@volreq = volume
			@volChanging = true if @volreq != self.volume
		}

	 state_var :mute, :type => :boolean, :editable => true, :action => proc{|on|
	 		@mutereq = on
	 		@muteChanging = true if self.mute != @mutereq
	 	}
	
	def initialize(a, b)
		super(a, b)
		uri = configuration[:uri]
		@switcherIP = uri.match(/(\d+.\d+.\d+.\d+)/).to_s #IP address of switcher
		@inputChanging = false
		@volChanging = false
		@muteChanging = false
		@inputReq = 0
		@volreq = 0
		@mutereq = false
		@inputGet = {"0" => [1, "COMP1"],
			"4" => [2, "COMP2"],
			"3" => [3, "HDMI1"],
			"13" => [4, "HDMI2"],
			"14" => [5, "HDMI3"],
			"16" => [6, "HDMI4"]} #Matches the get input command back to an input number and name
	end

	def run
		super
		socket = TCPSocket.new(@switcherIP, 23)
		micvol = sendTCP(socket, "\xBE\xEF\x03\x06\x00\x75\xF1\x02\x00\xA2\x20\x00\x00")[1].unpack('C')[0]
		DaemonKit.logger.info "Mic vol is #{micvol}, muting" if micvol != 0
		micvol.times{
			socket.puts "\xBE\xEF\x03\x06\x00\xC2\xF0\x05\x00\xA2\x20\x00\x00" #Sets the unused mic volume to 0 to avoid hardware issue where input audio is picked up by the mic. Mic doesn't have a mute
			socket.read 1 #The switcher sends back one packet - this limits the rate
			}
		begin
			while true
				readIn = sendTCP(socket,"\xBE\xEF\x03\x06\x00\xCD\xD2\x02\x00\x00\x20\x00\x00").unpack('C*')[1].to_s #Gets the input keys that match @inputGet
				self.video = @inputGet[readIn][0]
				inputName = @inputGet[readIn][1]
				self.volume = sendTCP(socket, "\xBE\xEF\x03\x06\x00\xCD\xC3\x02\x00\x50\x20\x00\x00")[1].unpack('C')[0] #Gets volume as an int
				self.mute = sendTCP(socket, "\xBE\xEF\x03\x06\x00\x75\xD3\x02\x00\x02\x20\x00\x00")[1].unpack('C')[0] == 1 #Gets mute as an bool
				#DaemonKit.logger.info("Input = #{self.video}:#{inputName}, Volume = #{@volume}, Mute = #{@mute}, InputChanging? = #{@inputChanging}, volChanging? = #{@volChanging}, muteChanging? = #{@muteChanging}")	
				socket = changeInput(socket, @inputReq) if @inputChanging
				socket = changeVol(socket, @volreq, self.volume) if @volChanging
				if @muteChanging
					@mutereq ? (socket.puts "\xBE\xEF\x03\x06\x00\xD6\xD2\x01\x00\x02\x20\x01\x00") : (socket.puts "\xBE\xEF\x03\x06\x00\x46\xD3\x01\x00\x02\x20\x00\x00") #Sends mute or unmute command
					socket.read 1
					@muteChanging = false
					DaemonKit.logger.info("Changing mute to #{@mutereq}")
				end
				sleep 1
			end
		rescue Exception => e
			DaemonKit.logger.error("Switcher Error: #{e.message}")
			socket.close
			sleep 1
			socket = TCPSocket.new(@switcherIP, 23)
			retry
		end
	end

	def sendTCP(socket, hexSend) #Method for sending info commands to switcher. Not used to change things
		sleep 0.2
		socket.puts hexSend
		sleep 0.2
		return socket.read(3)
	end

	def changeInput(socket, input)
		begin
			inputCommand = ["\xBE\xEF\x03\x06\x00\xFE\xD2\x01\x00\x00\x20\x00\x00",
				"\xBE\xEF\x03\x06\x00\x3E\xD0\x01\x00\x00\x20\x04\x00",
				"\xBE\xEF\x03\x06\x00\x0E\xD2\x01\x00\x00\x20\x03\x00",
				"\xBE\xEF\x03\x06\x00\x6E\xD6\x01\x00\x00\x20\x0D\x00",
				"\xBE\xEF\x03\x06\x00\x9E\xD6\x01\x00\x00\x20\x0E\x00",
				"\xBE\xEF\x03\x06\x00\x3E\xDF\x01\x00\x00\x20\x10\x00"] #Array of input set hex commands
			socket.puts inputCommand[input-1]
			socket.read 1
			readIn = sendTCP(socket,"\xBE\xEF\x03\x06\x00\xCD\xD2\x02\x00\x00\x20\x00\x00").unpack('C*')[1].to_s
			self.video = @inputGet[readIn][0]
			if self.video == input
				@inputChanging = false
			else
				raise "INPUT CHANGE #{input} to #{self.video} FAILED"
			end
		rescue Exception => e
		 	DaemonKit.logger.error("Error switching input: #{e.message}")
		 	socket.close
		 	socket = TCPSocket.new(@switcherIP, 23)
		 	retry
		end
		return socket
	end
	def changeVol(socket, newvol, oldvol)
		DaemonKit.logger.info("Changing volume from #{oldvol} to #{newvol}")
		begin
			oldvol.upto(newvol) do #Increments volume up to inputed volume
    			socket.puts "\xBE\xEF\x03\x06\x00\xAB\xC3\x04\x00\x50\x20\x00\x00"
    			socket.read 1
        	end
			newvol.upto(oldvol) do #Decrements volume down to inputed volume
     			socket.puts "\xBE\xEF\x03\x06\x00\x7A\xC2\x05\x00\x50\x20\x00\x00"
     			socket.read 1
        	end
		rescue Exception => e
			DaemonKit.logger.error("Error changing volume: #{e.message})")
			socket.close
			socket = TCPSocket.new(@switcherIP,23)
			self.volume = sendTCP(socket, "\xBE\xEF\x03\x06\x00\xCD\xC3\x02\x00\x50\x20\x00\x00")[1].unpack('C')[0] #Gets volume as an int
			oldvol = self.volume
			retry
		end
		return socket
	end
end