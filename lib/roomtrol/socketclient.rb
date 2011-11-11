module EventMachine
  class SocketClient < Connection
    include Deferrable

    attr_accessor :url

    def self.connect uri
      p_uri = URI.parse(uri)
      conn = EM.connect(p_uri.host, p_uri.port || 80, self) do |c|
        c.url = uri
      end
    end

    def post_init

    end

    def connection_completed

    end

    def stream &cb; @stream = cb; end
    def disconnect &cb; @disconnect = cb; end

    def receive_data data

    end

    def send_msg s
      frame = LibWebSocket::Frame.new(s)
      send_data frame.to_s
    end

    def unbind
      super
      @disconnect.call if @disconnect
    end
  end
end
