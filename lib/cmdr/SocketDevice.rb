require 'cmdr/socketclient'
require 'strscan'
require 'rubybits'
require 'socket'
require 'eventmachine'
require 'cmdr/communication'
module Cmdr
  class SocketDevice < CommDevice
    attr_accessor :socketclient
    
    def initialize(name, options, db_uri = "http://localhost:5984/rooms")
      configure do
        # uri in the form (Example) pjlink://129.133.125.197:4352
        uri :type => :uri
      end
      super(name, options, db_uri)
      throw "Must supply URI parameter" unless configuration[:uri]
      DaemonKit.logger.info "Creating socket device #{name} on #{configuration[:uri]}"
    end

    # Sends a string to the socketclient device
    # @param [String] string The string to send
    def send_string(string)
        begin
          @_conn.send_data string if @_conn
        rescue
        end
    end

    def operational= operational
      self.operational = operational
      event = { "device" => @hostname,
                "component" => @name,
                "location" => configuration[:uri],
                "summary" => "Communication lost with #{@name}",
                "eventClass" => "/Status/Device",
                "time" => Time.new,
                "severity" => 0}
      if self.operational
        Cmdr.send_event event
      else
        event["severity"] = 5
        Cmdr.send_event event
      end
      DaemonKit.logger.info "Sending event #{event}"
    end
    
    def connect
      EventMachine::SocketClient.connect(configuration[:uri])
    end

    def handle_connection_error
      operational=false
      EventMachine::Timer.new(1) do
        run
      end
    end

    def lost_communication
    	@_conn.close_connection
    end

    def me_message_received val
      true
    end
  end
end
