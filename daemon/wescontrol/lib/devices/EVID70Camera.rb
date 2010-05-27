class EVID70Camera < Wescontrol::RS232Device
	
	config_var :address
	state_var :power, 				:kind => 'boolean'
	state_var :zoom, 				:kind => 'percentage'
	state_var :focus, 				:kind => 'percentage'
	state_var :position, 			:kind => 'array'
	state_var :auto_focus, 			:kind => 'boolean'
	state_var :auto_white_balance, 	:kind => 'boolean'
	
	command :zoom_in
	command :zoom_out
	command :zoom_stop
	command :focus_near
	command :focus_far
	command :trigger_auto_focus
	command :trigger_auto_white_balance
	command :move_up_left, :kind => 'array'
	command :move_up_right, :kind => 'array'
	command :move_down_left, :kind => 'array'
	command :move_down_right, :kind => 'array'
	command :move_stop
	
	ERRORS = {
		1 => "Message length error (>14 bytes)",
		2 => "Syntax Error",
		3 => "Command buffer full",
		4 => "Command cancelled",
		5 => "No socket (to be cancelled)",
		0x41 => "Command not executable"
	}
	
	ZOOM = {
		1  => "0000",
		2  => "1606",
		3  => "2151",
		4  => "2860",
		5  => "2CB5",
		6  => "3060",
		7  => "32D3",
		8  => "3545",
		9  => "3727",
		10 => "38A9",
		11 => "3A42",
		12 => "3B4B",
		13 => "3C85",
		14 => "3D75",
		15 => "3E4E",
		16 => "3EF7",
		17 => "3FA0",
		18 => "4000"
	}
	
	def initialize(options)
		options = options.symbolize_keys
		puts "@Initializing camera on port #{options[:port]} with name #{options[:name]}"
		Thread.abort_on_exception = true
		@address = options[:address]
			
		@_commands = {
			#name => [message, callback]
			
			#action commands
			:power => proc{|on| "01 04 00 0" + (on ? "2" : "3")},
			:zoom => proc{|t| p,q,r,s = ZOOM[t].split(""); "01 04 47 0#{p} 0#{q} 0#{r} 0#{s}"},
			:zoom_in => "01 04 07 02",
			:zoom_out => "01 04 07 03",
			:zoom_stop => "01 04 07 00",
			:focus => proc{|f| p = (f * 11 + 1).round.to_s(16); "01 04 48 0#{p} 00 00 00"},
			:focus_near => "01 04 08 03",
			:focus_far => "01 04 08 02",
			:auto_focus => proc{|on| "01 04 38 0" + (on ? "2" : "3")},
			:trigger_auto_focus => "01 04 18 01",
			:auto_white_balance => "01 04 35 00",
			:manual_white_balance => "01 04 35 05",
			:trigger_auto_white_balance => "01 04 10 05",
			:move_up => proc{|v, w| pan_tilt(3, 1, v, w)},
			:move_down => proc{|v, w| pan_tilt(3, 2, v, w)},
			:move_left => proc{|v, w| pan_tilt(1, 3, v, w)},
			:move_right => proc{|v, w| pan_tilt(2, 3, v, w)},
			:move_up_left => proc{|v, w| pan_tilt(1, 1, v, w)},
			:move_up_right => proc{|v, w| pan_tilt(2, 1, v, w)},
			:move_down_left => proc{|v, w| pan_tilt(1, 2, v, w)},
			:move_down_right => proc{|v, w| pan_tilt(2, 2, v, w)},
			:move_stop => proc{|v, w| pan_tilt(3, 3, v, w)},
			:position => proc{|v, w, y, z|
				vv = "%02x" % (v*17+1).round
				ww = "%02x" % (w*16+1).round
				yyyy = ("%04x" % y).split("").collect{|x| "0#{x}"}.join(" ")
				zzzz = ("%04x" % z).split("").collect{|x| "0#{x}"}.join(" ")
				"01 06 02 #{vv} #{ww} #{yyyy} #{zzzz}"
			}
		}
		
		@_requests = {	
			#Request commands
			:lens_request => ["09 7E 7E 00", proc {|resp|
				this.zoom = resp[2..5].collect{|x| x.to_s(16)}.join.to_i(16)
				this.focus = resp[8..11].collect{|x| x.to_s(16)}.join.to_i(16)
				this.auto_focus = resp[13] & 1
				this.focussing = resp[14] & 2
				this.zooming = resp[14] & 1
			}],
			#:camera_control_request => ["09 7E 7E 01", proc {|resp|
			#	gives stuff like gain, exposure, aperture, etc
			#}],
			:power_inquiry => ["09 04 00", proc{|resp|
				this.power = resp[2] == 2
			}],
			:position_inquiry => ["09 06 12", proc{|res|
				this.position = [
					resp[2..5].collect{|x| x.to_s(16).join.to_i(16)}, #pan position
					resp[6..9].collect{|x| x.to_s(16).join.to_i(16)}, #tilt position
				]
			}]
		}
		
		@_r_enum = HashEnum.new(@_requests)
		
		@_last_command = {}
		@_response = nil
		@_send_queue = []
		@_last_sent_time = Time.now
	
		super(:port => options[:port], :baud => 9600, :data_bits => 8, :stop_bits => 1, :name => options[:name])
		
		Thread.new {
			read
		}
				
		ready_to_send = true
	end
	
	def method_missing(method_name, *args)
		if @commands[method_name]
			if @commands[method_name].class == Proc
				_message = @commands[method_name].call(*args)
			elsif @commands[method_name].class == String
				_message = @commands[method_name]
			else
				throw "Method must be either a function or a string"
			end
			deferrable = EM::DefaultDeferrable.new
			send _message, deferrable
			return deferrable
		else
			super.method_missing(method_name, *args)
		end
	end
	
	private
			
	def pan_tilt(c1, c2, v, w)
		vv = "%02x" % (v*17+1).round
		ww = "%02x" % (w*16+1).round
		"01 06 01 #{vv} #{ww} #{"%02x" % c1} #{"%02x" % c2}"
	end
	
	def send message, deferrable
		@_send_queue.unshift ["81 #{message} FF".hexify, deferrable]
		ready_to_send = ready_to_send; #this makes sure that we send the message if we're ready
	end
	
	def ready_to_send=(state)
		@_ready_to_send = state;
		@_ready_to_send = true if Time.now - @_last_sent_time > 1

		if @_ready_to_send
			if @_send_queue.size > 0
				#we put the command currently being sent into -1 (@_last_command
				#is a hash, so we can do that), then it's moved to the correct
				#socket number when we get the ACK
				@_last_command[-1] = @_send_queue.pop
			else
				@_last_command[-1] = @_r_enum.next
			end
			@_last_sent_time = Time.now
			@_ready_to_send = false
			send_string(@_last_command[-1][0])
		end
	end
	
	def ready_to_send; @_ready_to_send; end

	def read
		buffer = []
		while true do
			buffer << @serial_port.getc
			if buffer[-1] == 0xFF #0xFF terminates each packet
				if buffer[1] >> 4 == 4 #ACK
					#the last four bits tell us the socket number, so we move
					#the current command (stored in -1) to there
					@_last_command[buffer[1] & 0b00001111] = @_last_command[-1]
				 	this.ready_to_send = true
				elsif buffer[1] >> 4 == 5 #completion
					deferrable = @_last_command[buffer[1] & 0b00001111][1]
					if buffer.size == 3 #command
						deferrable.set_deferred_status :succeeded
					else #request
						if deferrable.class == Proc
							deferrable.send(@buffer[2..-2])
						else
							deferrable.set_deferred_status :succeeded, @buffer[2..-2]
						end
					end
				elsif buffer[1] >> 4 == 6 #error
					_error = ERRORS[buffer[2]]
					puts "Camera error: #{_error}"
					deferrable = @_last_command[buffer[1] & 0b00001111][1]
					deferrable.set_deferred_status :failed, _error if deferrable.class == EM::Deferrable
				end
				buffer = []
			end
		end
	end
end

class String
	def hexify
		self.gsub(" ", "").scan(/../).collect{|x| x.hex}.pack("c*")
	end
end

class HashEnum
	def initialize(hash)
		@_keys = hash.keys
		@_counter = -1
		@_hash = hash
	end
	def next
		@_counter += 1
		hash[@_keys[@_counter % hash.size]]
	end
end