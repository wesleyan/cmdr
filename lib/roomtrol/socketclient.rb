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

    def unbind
      @disconnect.call if @disconnect
      DaemonKit.logger.info "Attempting to reconnect to #{@_ip}"
      EventMachine::Timer.new(1) do
        reconnect(@_ip, @_port || 80)
      end
    end
  end
end
