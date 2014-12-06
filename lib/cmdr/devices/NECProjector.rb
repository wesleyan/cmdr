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
# "name": "NECProjector",
# "depends_on": "Projector",
# "description": "Controls most NEC projectors",
# "author": "Micah Wylde",
# "email": "mwylde@wesleyan.edu",
# "type": "Projector"
#}
#---

class NECProjector < Projector
  class NECProjectorFormat < RubyBits::Structure
    unsigned :id1,     8,    "Identification data assigned to each command"
    unsigned :id2,     8,    "Identification data assigned to each command"
    unsigned :p_id,    8,    "Projector ID"
    unsigned :m_code,  4,    "Model code for projector"
    unsigned :len,     12,   "Length of data in bytes"
    variable :data,          "Packet data", :length => :len, :unit => :byte
    unsigned :checksum,8,    "Checksum"
    
    checksum :checksum do |s|
      s[0..-2].inject{|sum, byte| sum + byte} & 255
    end
  end
  
  class << self
    # Given an index into @_commands, this function gives the binary
    # string that does that request
    # @param [Symbol] name The index of @commands to use (the name of the request)
    # @return [String] A binary string which, when sent to the projector, should 
    #   produce the desired response
    def request_for_name(name, *args)
      cmd = @_commands[name][0..-2].collect{|element| 
        element.class == Proc ? element.call(*args) : element
      }
      package_message(*cmd)
    end

    def unpack_unsigned s, offset, length
      number = 0
      s_iter = s.bytes
      byte = 0
      # advance the iterator by the number of whole or partial bytes in the offset (offset div 8)
      ((offset.to_f/8).ceil).times{|i| byte = s_iter.next}
      
      length.times{|bit|
        byte = s_iter.next if offset % 8 == 0
        src_bit = (7-offset%8)
        number |= (1 << (length-1-bit)) if (byte & (1 << src_bit)) > 0
        #puts "Reading: #{src_bit} from #{"%08b" % byte} => #{(byte & (1 << src_bit)) > 0 ? 1 : 0}"
        offset += 1
      }
      number
    end

    def package_message(id1, id2, data, projector_id = 0, model_code = 0)
      # create a new BitPack object to pack the message into
      message = NECProjectorFormat.new(:id1 => id1, :id2 => id2,
                                       :p_id => projector_id,
                                       :m_code => model_code)
      
      if data
        message.len = data.size
        message.data = data
      else
        message.len = 0
        message.data = ""
      end
        
      return message.to_s
    end
  
    def interpret_message(msg)
      message = NECProjectorFormat.from_string(msg)[0]

      cm = {}
      cm["id1"] = message.id1
      cm["id2"] = message.id2
      cm["projector_id"] = message.p_id
      cm["model_code"] = message.m_code
      cm["data_size"] = message.len

      cm["data"] = message.data.bytes.to_a

      cm["checksum"] = message.data.bytes.to_a[-1]
    
      #Test whether the bit 8 is set or not. If it is, the response is acknowledged
      #printf("id1: %08b\n", cm["id1"])
      #cm["ack"] = cm["id1"] & 2**7 != 0
      cm["ack"] = cm["id1"] >> 4 == 2

      #puts "ACK" if cm["id1"] >> 4 == 0xA
      #puts "NACK" if cm["id1"] >> 4 == 0x2
      return cm
    end
    
    def interpret_error(frame)
      error_codes = {0 => "Not supported", 1 => "Parameter error", 2 => "Operation mode error", 
        3 => "Gain-related error", 4 => "Logo transfer error"}
      if frame['data'] && frame['data'][0]
        #DaemonKit.logger.error "#{frame['id2'].to_s(16)}: The response was not acknowledged: #{error_codes[frame['data'][0]]}: #{frame['data'][1]}"
        return "The response was not acknowledged: #{error_codes[frame['data'][0]]}: #{frame['data'][1]}"
      end
    end
  end
  
  # TCP port number is 7142
  RGB1   = 1
  RGB2   = 2
  VIDEO  = 6
  SVIDEO = 11
  LAN    = 32
  INPUT_HASH = {"RGB1" => 1, "RGB2" => 2, "VIDEO" => 6, "SVIDEO" => 11, "LAN" => 32}
  
  MODEL_MAP = {[10, 4, 9]=>"NP300", [3, 0, 6]=>"VT80", [12, 0, 8]=>"NP1150/NP2150/NP3150", [11, 1, 0]=>"NP62", [10, 1, 9]=>"NP500", [2, 2, 3]=>"LT240K/LT260K", [12, 2, 9]=>"VT800", [4, 0, 3]=>"GT5000", [4, 1, 1]=>"GT2150", [2, 1, 3]=>"LT220", [2, 0, 6]=>"LT380", [1, 2, 3]=>"MT1075", [10, 3, 9]=>"NP400", [8, 0, 7]=>"NP4000/NP4001", [6, 0, 5]=>"WT610/WT615", [3, 0, 4]=>"VT770", [11, 0, 0]=>"NP41/61", [10, 0, 9]=>"NP600", [5, 0, 3]=>"HT1000", [2, 0, 5]=>"LT245/LT265", [1, 0, 6]=>"NP1000/NP2000", [12, 1, 9]=>"NP901W", [4, 1, 3]=>"GT6000", [4, 0, 1]=>"GT1150", [1, 0, 1]=>"MT1060/MT1065", [10, 0, 8]=>"VT700", [2, 1, 6]=>"LT280", [12, 1, 8]=>"NP3151W", [10, 2, 9]=>"NP500", [6, 0, 3]=>"WT600", [5, 0, 4]=>"HT1100", [3, 0, 7]=>"VT90", [2, 0, 3]=>"LT240/LT260", [12, 0, 9]=>"NP905", [1, 1, 3]=>"MT860"}
  
  ERROR_STATUS = [
    ["Lamp cover error", "Temperature error", "", "", "Fan error", "Power error", "Lamp error", "Lamp has reached its end of life"],
    ["Lamp has been used beyond its limit", "Formatter error", "Lamp2 error"],
    ["", "FPGA error", "Temperature error", "Lamp housing error", "Lamp data error", "Mirror cover error", "Lamp2 has reached its end of life", "Lamp2 has been used beyond its limit"],
    ["Lamp2 housing error", "Lamp2 data error", "High temperature due to dust pile-up", "A foreign object sensor error", "Pump error"]
  ]
  
  @_commands = {
    #format is :name => [id1, id2, data, callback]
    :set_power      => [2, proc {|on| on ? 0 : 1}, nil, nil],
    :set_video_mute => [2, proc {|on| on ? 0x10 : 0x11}, nil, nil],
    :set_input      => [2, 3, proc {|source| [1, INPUT_HASH[source]].pack("cc")}, nil],
    :set_brightness => [3, 0x10, proc {|brightness| [0, 0xFF, 0, brightness, 0].pack("ccccc")}, nil],
    :set_volume     => [3, 0x10, proc {|volume| [5, 0, 0, (volume * 63).round, 0].pack("ccccc")}, nil],
    :set_mute       => [2, proc {|on| on ? 0x12 : 0x13}, nil, nil],
    :image_freeze   => [1, 0x98, proc {|on| on ? 1 : 2}, nil],
    :running_sense  => [0, 0x81, nil, proc {|frame|
      self.power       = frame["data"][0] & 2**1 != 0
      @cooling_maybe   = frame["data"][0] & 2**5 != 0
      if @cooling_maybe != @cooling
        cooling_maybe_was = @cooling_maybe
        EM::add_timer(4) do
          self.cooling = @cooling_maybe if @cooling_maybe == cooling_maybe_was
        end
      end
      #projector is warming if it is doing power processing (bit 7) and not cooling
      #this is not supported on MT1065's, but is on NPs
      @warming_maybe     = (frame["data"][0] & 2**7 != 0) && !@cooling
      if @warming_maybe != @warming
        warming_maybe_was = @warming_maybe
        EM::add_timer(4) do
          self.warming = @warming_maybe if @warming_maybe == warming_maybe_was
        end
      end
    }],
    :common_data_request => [0, 0xC0, nil, proc {|frame|
      data = frame["data"]
      # @power = data[3] == 1
      # @cooling = data[4] == 1
      case data[6..7]
        when [1, 1] then self.input = "RGB1"
        when [2, 1] then self.input = "RGB2"
        when [1, 2] then self.input = "VIDEO"
        when [1, 3] then self.input = "SVIDEO"
        when [2, 7] then self.input = "LAN"
      end
      self.video_mute = data[28] == 1
      self.mute = data[29] == 1
      self.image_freeze = data[31] == 1
      self.model = MODEL_MAP[[data[0], data[69], data[70]]]
      self.has_signal = data[84] != 1
      self.picture_displaying = data[84] == 0
      # data[84] == 4 means LAN is displaying ??
      # This must have something to do with how displaying from LAN works- I thought it was 
      # just another input, but I guess not. Will have to actually test before I know if I
      # need to change anything
    }],
    :projector_info_request => [0, 0xBF, [2].pack("c"), proc {|frame|
      data = frame['data']
      self.video_mute = data[6] == 1
      self.mute = data[7] == 1
    }],
    :lamp_information => [3, 0x8A, nil, proc {|frame|
      data = frame["data"]
      #projector_name is a null-terminated string taking up at most bytes 0..48
      self.projector_name = data[0..[48, data.index(0)].min].pack("c*")
      #they use a bizarre method of encoding for these, which is essentially bytes 82..85 
      #contatenated in hex in inverse order. Also, despite the name, values are in seconds.
      def get_hours(array)
        return (array.reverse.collect{|hex| hex.to_s(16)}.join.to_i(16)/3600.0).round()
      end
      self.lamp_hours      = get_hours(data[82..85])
      self.filter_hours    = get_hours(data[86..89])
      self.projector_usage = get_hours(data[94..97])
    }],
    :lamp_remaining_info => [3, 0x94, nil, proc {|frame|
      self.percent_lamp_used = 100-frame['data'][4] #percent remaining is what's returned
    }],
    :volume_request => [3, 4, [5, 0].pack("cc"), proc {|frame|
      #potentially interesting note: you can detect whether you can change gain with DATA01
      data = frame["data"]
      #if data[0] != 0 #if it's 0, "display [gain] impossible"
        #@max_volume = data[1] + data[2] * 2**8
        #@min_volume = data[3] + data[4] * 2**8
        self.volume = (data[7] + data[8] * 2**8) / 63.to_f
        #puts "Volume should be [#{@min_volume}, #{@max_volume}]"
      #end
    }],
    :mute_information => [0, 0x85, [3].pack("c"), proc {|frame|
      data = frame['data']
      self.video_mute = data[0] == 1
      self.mute = data[1] == 1
    }],
    :input_information => [0, 0x85, [2].pack("c"), proc {|frame|
      data = frame['data']
      case data[2..3]
        when [1, 1] then self.input = "RGB1"
        when [2, 1] then self.input = "RGB2"
        when [1, 2] then self.input = "VIDEO"
        when [1, 3] then self.input = "SVIDEO"
        when [2, 7] then self.input = "LAN"
      end
    }],
    :error_status_request => [0, 0x88, nil, proc{|frame|
      data = frame["data"]
      @errors = []
      data.each_index{|i|
        8.times{|t|
          if data[i] & 2 ** t != 0
            @errors << ERROR_STATUS[i][t]
            # error(ERROR_STATUS[i][t])
            DaemonKit.logger.error "Projector Error: #{ERROR_STATUS[i][t]}"
          end
        }
      }
    }]
  }
  
  
  state_var :projector_name,     :type => :string,   :editable => false
  state_var :projector_id,       :type => :string,   :editable => false
  state_var :projector_usage,    :type => :number,   :editable => false
  state_var :has_signal,         :type => :boolean,  :editable => false
  state_var :picture_displaying, :type => :boolean,  :editable => false
  state_var :volume,             :type => :percentage
  state_var :mute,               :type => :boolean
  state_var :image_freeze,       :type => :boolean
  
  requests do |r|
    r.send :running_sense,          request_for_name(:running_sense),          1.0
    r.send :volume_request,         request_for_name(:volume_request),         0.5
    r.send :mute_information,       request_for_name(:mute_information),       0.5
    r.send :projector_info_request, request_for_name(:projector_info_request), 0.3
    r.send :lamp_information,       request_for_name(:lamp_information),       0.05
    r.send :lamp_remaining_info,    request_for_name(:lamp_remaining_info),    0.05
    r.send :error_status_request,   request_for_name(:error_status_request),   0.2
  end
  
  responses do |r|
    recognize = proc{|id2, ack, msg|
      frame = interpret_message(msg)
      frame["id2"] == id2 && frame["ack"] == ack
    }.curry
    
    # for each command in @_commands, create a matching rule. The recognize.(cmd[1]) 
    # statement is doing partial application of the function recognize, which is a new
    # feature of Ruby 1.9
    @_commands.each{|name, cmd|
      if cmd[-1].is_a? Proc
        r.match name, recognize.(cmd[1], true), proc {|msg|
          frame = self.class.interpret_message(msg)
          self.instance_exec(frame, &cmd[-1])
        }
      else
        r.ack recognize.(cmd[1], true)
      end
      r.error name, recognize.(cmd[1], false), proc {|msg|
        frame = self.class.interpret_message(msg)
        self.class.interpret_error(frame)
      }
    }
  end
  
  def initialize(name, options)
  configure do
    baud 9600
    message_end lambda{|msg|
      return false if msg.size < 6
      bytes = msg.bytes.to_a
      return false if bytes[0] == 0
      return false unless NECProjectorFormat.checksum_field[1].call(bytes) == bytes[-1]
      data_size = NECProjector.unpack_unsigned msg, 28, 12
      # we make sure that we have the right number of bytes given the given data_size
      return false unless msg.size == 6 + data_size
      return true
    }
  end
    options = options.symbolize_keys
    DaemonKit.logger.info "@Initializing projector on port #{options[:port]} with name #{name}"

    super(name, :port => options[:port], :baud => 9600, :data_bits => 8, :stop_bits => 1)
    
    @max_volume = 63
    @max_volume = 0
    
    @_commands = self.class.instance_variable_get(:@_commands)
  end
  
  def method_missing(method_name, *args)
    if @_commands[method_name]
      cmd = @_commands[method_name][0..-2].collect{|element| element.class == Proc ? element.call(*args) : element}
      deferrable = EM::DefaultDeferrable.new
      do_message self.class.package_message(*cmd), deferrable
      deferrable
    else
      super.method_missing(method_name, *args)
    end
  end
end
