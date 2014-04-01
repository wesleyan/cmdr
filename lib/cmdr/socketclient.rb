# Copyright (C) 2014 Wesleyan University
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'cmdr/communication'

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

    def unbind
      @disconnect.call if @disconnect
      EventMachine::Timer.new(1) do
        DaemonKit.logger.info "Attempting to reconnect to #{@_ip}"
        event = {"device" => @hostname,
                 "component" => @name,
                 "summary" => "Disconnected from #{@name}",
                 "eventClass" => "/Status/Device",
                 "severity" => 5}
        Cmdr.send_event event
        reconnect(@_ip, @_port || 80)
      end
    end
  end
end
