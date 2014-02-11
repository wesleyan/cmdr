require 'roomtrol/socketclient'
require 'strscan'
require 'rubybits'
require 'socket'
require 'eventmachine'

def send_event severity 
      @_event = {"device" => "#{@hostname}", 
                 "component" => "#{@name}", 
                 "location" => "#{configuration[:uri]}",
                 "title" => "Communication lost with #{@name}",
                 "description" => "Communication lost with #{@name}", 
                 "device_type" => "/Status/Device",
                 "time" => Time.new,
                 "severity" => severity}
      EM.defer do
        begin
          DaemonKit.logger.info("Received error: #{@_event}")
          serv = XMLRPC::Client.new2('http://localhost:5000/messages/')
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