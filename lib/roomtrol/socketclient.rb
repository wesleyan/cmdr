module EventMachine
  class SocketClient < Connection
    include Deferrable

    attr_accessor :url

    def self.connect uri
      p_uri = URI.parse(uri)
      @@ip = p_uri.host
      @@port = p_uri.port
      conn = EventMachine::connect(p_uri.host, p_uri.port || 80, self) do |c|
        c.url = uri
      end
    end

    def post_init
      @_ip = @@ip
      @_port = @@port
      comm_inactivity_timeout = 1.0
      pending_connect_timeout = 5.0
    end

    def connection_completed
    end

    def stream &cb 
      @stream = cb 
    end
      
    def disconnect &cb; @disconnect = cb; end

    def receive_data data
      @stream.call data if @stream
    end

    #def send_msg s
    #
    #end
    
    def send data
    end

    def send_event severity 
      @_event = {"device" => "#{@hostname}", 
                 "component" => "#{@name}", 
                 "summary" => "Communication lost with #{@name}", 
                 "eventClass" => "/Status/Device",
                 "severity" => severity}
      EM.defer do
        begin
          DaemonKit.logger.info("Received error: #{@_event}")
          serv = XMLRPC::Client.new2('http://roomtrol:Pr351d3nt@imsvm:8080/zport/dmd/ZenEventManager')
          serv.call('sendEvent', @_event)
        rescue
        end
      end
    end

    def operational= operational
      self.operational = operational
      if self.operational
        send_event 0
      else
        send_event 5
      end
    end

    def unbind
      @disconnect.call if @disconnect
      EventMachine::Timer.new(1) do
        DaemonKit.logger.info "Attempting to reconnect to #{@_ip}"
        operational=false
        reconnect(@_ip, @_port || 80)
      end
    end
  end
end
