# Copyright (C) 2014 Wesleyan University
#
# This file is part of cmdr-devices.
#
# cmdr-devices is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# cmdr-devices is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with cmdr-devices. If not, see <http://www.gnu.org/licenses/>.

#---
#{
# "name": "EVID70Camera",
# "depends_on": "RS232Device",
# "description": "Controls the Sony EVID70 camera, and probably other similar devices",
# "author": "Micah Wylde",
# "type": "Camera",
# "email": "mwylde@wesleyan.edu"
#}
#---

class EVID70Camera < Cmdr::RS232Device
  
  configure do
    address :type => :string
    message_timeout 0.2
  end
  
  state_var :power,         :type => :boolean
  state_var :zoom,        :type => :percentage
  state_var :focus,         :type => :percentage
  state_var :position,      :type => :array
  state_var :auto_focus,      :type => :boolean
  state_var :auto_white_balance,  :type => :boolean
  
  state_var :focussing,           :type => :boolean, :editable => false
  state_var :zooming,             :type => :boolean, :editable => false
  
  command :zoom_in
  command :zoom_out
  command :zoom_stop
  command :focus_near
  command :focus_far
  command :focus_stop
  command :trigger_auto_focus
  command :trigger_auto_white_balance
  command :move_up_left, :type => :array
  command :move_up_right, :type => :array
  command :move_down_left, :type => :array
  command :move_down_right, :type => :array
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
  
  def initialize(name, options)
    options = options.symbolize_keys
    DaemonKit.logger.info "Initializing camera on port #{options[:port]} with name #{options[:name]}"
    Thread.abort_on_exception = true
    @address = options[:address]
      
    @_commands = {
      #name => [message, callback]
      
      #action commands
      :set_power => proc{|on| "01 04 00 0" + (on ? "2" : "3")},
      :set_zoom => proc{|t| p,q,r,s = ZOOM[t].split(""); "01 04 47 0#{p} 0#{q} 0#{r} 0#{s}"},
      :zoom_in => "01 04 07 02",
      :zoom_out => "01 04 07 03",
      :zoom_stop => "01 04 07 00",
      :set_focus => proc{|f| p = (f * 11 + 1).round.to_s(16); "01 04 48 0#{p} 00 00 00"},
      :focus_near => "01 04 08 03",
      :focus_far => "01 04 08 02",
      :focus_stop => "01 04 08 00",
      :set_auto_focus => proc{|on| "01 04 38 0" + (on ? "2" : "3")},
      :trigger_auto_focus => "01 04 18 01",
      :set_auto_white_balance => proc{|on| "01 04 0" + (on ? "0" : "5")},
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
      :set_position => proc{|v, w, y, z|
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
        self.zoom = resp[2..5].collect{|x| x.to_s(16)}.join.to_i(16)
        self.focus = resp[8..11].collect{|x| x.to_s(16)}.join.to_i(16)
        self.auto_focus = resp[13] & 1
        self.focussing = resp[14] & 2
        self.zooming = resp[14] & 1
      }],
      #:camera_control_request => ["09 7E 7E 01", proc {|resp|
      # gives stuff like gain, exposure, aperture, etc
      #}],
      :power_inquiry => ["09 04 00", proc{|resp|
        self.power = resp[2] == 2
      }],
      :position_inquiry => ["09 06 12", proc{|resp|
        self.position = [
          resp[2..5].collect{|x| x.to_s(16)}.join.to_i(16), #pan position
          resp[6..9].collect{|x| x.to_s(16)}.join.to_i(16), #tilt position
        ]
      }]
    }
    
    @_r_enum = HashEnum.new(@_requests)
    
    @_last_command = {}
    @_response = nil
    @_send_queue = []
    @_last_sent_time = Time.now
  
    super(name, options)
        
    ready_to_send = true
  end
  
  def method_missing(method_name, *args)
    if @_commands[method_name]
      if @_commands[method_name].class == Proc
        _message = @_commands[method_name].call(*args)
      elsif @_commands[method_name].class == String
        _message = @_commands[method_name]
      else
        throw "Method must be either a function or a string"
      end
      deferrable = EM::DefaultDeferrable.new
      send_command _message, deferrable
      self.ready_to_send = ready_to_send #this makes sure that we send the message if we're ready
      return deferrable
    else
      super.method_missing(method_name, *args)
    end
  end
  
  def read data
    @_buffer ||= []
    data.each_byte{|byte|
      @_buffer << byte
      if @_buffer[-1] == 0xFF #0xFF terminates each packet
        if @_buffer[1] >> 4 == 4 #ACK
          DaemonKit.logger.debug("ACK received")
          #the last four bits tell us the socket number, so we move
          #the current command (stored in -1) to there
          @_last_command[@_buffer[1] & 0b00001111] = @_last_command[-1]
          self.ready_to_send = true
        elsif @_buffer[1] >> 4 == 5 #completion
          cmd = @_last_command[@_buffer[1] & 0b00001111]
          if @_buffer.size == 3 && cmd #command
            cmd[1].set_deferred_status :succeeded
          else #request
            #we don't get ACKs for requests, so the command never gets moved
            if @_last_command[-1][1].class == Proc
              @_last_command[-1][1].call(@_buffer[2..-2])
            else
              @_last_command[-1][1].set_deferred_status :succeeded, @_buffer[2..-2]
            end
          end
        elsif @_buffer[1] >> 4 == 6 #error
          _error = ERRORS[@_buffer[2]]
          DaemonKit.logger.error "Camera error: #{_error}"
          cmd = @_last_command[@_buffer[1] & 0b00001111]
          if cmd
            cmd[1].set_deferred_status :failed, _error if cmd[1].is_a? EM::Deferrable
          end
        end
        @_buffer = []
      end
      
    }
  end
  
  private
      
  def pan_tilt(c1, c2, v, w)
    vv = "%02x" % (v*17+1).round
    ww = "%02x" % (w*16+1).round
    "01 06 01 #{vv} #{ww} #{"%02x" % c1} #{"%02x" % c2}"
  end
  
  def send_command message, deferrable
    @_send_queue.unshift ["81 #{message} FF".hexify, deferrable]
  end
  
  def ready_to_send=(state)
    @_ready_to_send = state;
    @_ready_to_send = true if Time.now - @_last_sent_time > 1

    if @_ready_to_send
      if @_send_queue.size == 0
        return
        request = @_r_enum.next
        send_command request[0], request[1]
      end
      #we put the command currently being sent into -1 (@_last_command
      #is a hash, so we can do that), then it's moved to the correct
      #socket number when we get the ACK
      @_last_command[-1] = @_send_queue.pop
      @_last_sent_time = Time.now
      @_ready_to_send = false
      send_string(@_last_command[-1][0])
    end
  end
  
  def ready_to_send; @_ready_to_send; end
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
    @_hash[@_keys[@_counter % @_hash.size]]
  end
end
