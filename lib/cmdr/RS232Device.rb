require 'serialport'
require 'strscan'
require 'rubybits'
require 'xmlrpc/client'
require 'cmdr/communication'
module Cmdr
  class RS232Device < CommDevice
    def initialize(name, options, db_uri = "http://localhost:5984/rooms")
      configure do
        port :type => :port
        baud :type => :integer, :default => 9600
        data_bits 8
        stop_bits 1
        parity 0
        wait_until_ack false
      end
      super(name, options, db_uri)
      throw "Must supply serial port parameter" unless configuration[:port]
      DaemonKit.logger.info "Creating RS232 Device #{name} on #{configuration[:port]} at #{configuration[:baud]}"
      @_serialport = SerialPort.new(configuration[:port], configuration[:baud])
    end

    # Sends a string to the serial device
    # @param [String] string The string to send
    def send_string(string)
      EM.defer do
        begin
          @_serialport.write string if @_serialport
        rescue
        end
      end
    end

    # Creates a fake evented serial connection, which calls the passed-in callback when
    # data is received. Note that you should only call this method once.
    # @param [Proc] cb A callback that should handle serial data
    def serial_reader &cb
      Thread.new do
        loop do
          begin
            data = @_serialport.sysread(4096)
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK, EOFError
            sleep(0.05)
          rescue Errno::ECONNRESET, Errno::ECONNREFUSED
            DaemonKit.logger.error("Connection refused")
            break
          end

          if data
            EM.next_tick {
              cb.call(data)
            }
          end
        end
      end
    end
    

    def connect
      self.serial_reader
    end

    def unless_operational
      super
      send_event 0
    end

    def lost_communicaiton
      send_event 5
    end

    def prescan data
      @_buffer ||= ""
      @_buffer = "" if @_buffer.size > 50
      @_buffer << data
      return @_buffer
    end

    def do_message_end data, handle_message, message_received
      loop_message_received = false
      start = 0
      (start+1).upto(@_buffer.size){|_end|
        if instance_exec(@_buffer[start.._end], &configuration[:message_end])
          ready = handle_message.call(@_buffer[start.._end])
          @_buffer = @_buffer[(_end+1)..-1]
          loop_message_received = true
          message_received |= loop_message_received if ready
          break
        end
      }
      loop_message_received, message_received
    end
  end
end
