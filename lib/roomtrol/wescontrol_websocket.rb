require 'rubygems'
require 'em-websocket'
require 'json'
require 'mq'

module Wescontrol
  # Wescontrol websocket server. Used to provide better interactivity to
  # the touchscreen interface. Communication is through JSON, like for
  # Wescontrol HTTP. Due to the nature of web sockets, message can either
  # be sent from the server to the client or the other direction. In general,
  # messages sent to the client are to notify of state changes, like a projector
  # turning on or a source being changed, while those from the client are
  # requests to change to state of a device or send a command. Note that every
  # message has an "id" field, which is merely a unique identifier for that
  # message. All responses to a request (whichever direction it travels) should
  # include the id of the request. Any string can be used as an id, but GUIDs
  # are recommended.
  #
  # #Messages
  # ##Client -> Server
  # ###state_get
  # Gets information about the current state of a variable
  #
  #     {
  #       "id": "DD2297B4-6982-4804-976A-AEA868564DF3",
  #       "type": "state_get",
  #       "device": "Projector",
  #       "var": "power"
  #     }
  #
  # This should produce the response:
  #
  #     {
  #       "id": "DD2297B4-6982-4804-976A-AEA868564DF3",
  #       "result": true
  #     }
  #
  # ###state_set
  # Sets the state of a variable
  #
  #     {
  #        "id": "D62F993B-E036-417C-948B-FEA389480984",
  #        "type": "state_set",
  #        "device": "Projector",
  #        "var": "power",
  #        "value": true
  #     }
  #
  # This will produce an ACK, which lets the client know that the request
  # was received.
  #
  #     {
  #        "id": "D62F993B-E036-417C-948B-FEA389480984",
  #        "ack": true
  #     }
  #
  # In order to know if this was successful, the client must wait for a
  # change in the variable (power, in this case) and ensure that it has
  # become the expected value.
  #
  # ###command
  # Executes a command
  #
  #     {
  #        "id": "D62F993B-E036-417C-948B-FEA389481512",
  #        "type": "command",
  #        "device": "IREmitter",
  #        "name": "send_command",
  #        "args": ["play"]
  #     }
  #
  # This will also produce an ACK, as above.
  #
  # ## Server -> Client
  # ### connected
  # When a client connects, the server sends it a bunch of useful information
  # for setting itself up. The message looks like this:
  #
  #     {
  #       "id": "AEF80ED8-35C6-4EBC-B80C-218C306CA393",
  #       "type": "connection",
  #       "building": {
  #          "guid": "cc7e9b6fe3e2757deba97d8d83157515",
  #          "name": "Albritton"
  #       },
  #       "room": {
  #          "guid": "99b9b6d7bc4c69844b9b70ff601e3124",
  #          "name": "004",
  #          "projector: "Projector",
  #          "switcher": "Extron",
  #          "volume": "Extron",
  #          "dvdplayer": "dvdplayer"
  #       },
  #       "devices": [
  #         {
  #            "guid": "0552c56cf2517e5d4b65d859541273fe",
  #         }
  #       ]
  #     }
  
  class WescontrolWebsocket

    def run
      AMQP.start(:host => "localhost") do
        @mq = MQ.new
        @update_channel = EM::Channel.new
        @deferred_responses = {}

        @queue_name = 'roomtroll:http:#{self.object_id}'
        @queue = @amq.queue(@queue_name)

        @queue.subscribe{ |json|
          msg = JSON.parse(json)

          if msg['type'] == 'update'
            @update_channel.push(msg)

          elsif msg['type'] == 'response'
            if @deferred_responses[msg["id"]]
              @deferred_responses.delete(msg["id"]).succeed(msg) 
            end
                 
          end
        }
        
        EM::WebSocket.start({
                              :host => "0.0.0.0",
                              :port => 8000,
                              :debug => true
                              #:secure => true  
                            }) do |ws|

          ws.onopen do 
            DaemonKit.logger.debug "New connection on #{ws.signature}"


            # subscribe to channel that gets the
            # updates directly from the mq
            
            sid = @update_channel.subscribe { |msg|
              ws.send msg
            }

            # send the client the required
            # information about room, devices, etc.
            # to set it up
            
            init_message = {
              'id' => UUIDTools::UUID.random_create.to_s,
              'type' => 'init'
              #'building' =>
              #'room' =>
              #'devices' =>
              #etc
            }

            ws.send init_message.to_json
              
          end

          ws.onmessage do |json|

            resp = {'id' => message['id'], 'received' => true}.to_json
            ws.send resp

            begin
              message = JSON.parse(json)

              device_req = {
                :id => message['id'],
                :queue => @queue_name,
                :device => message['device']
              }
              
              case message['type']
              
              when "get"
                device_req[:type] = :state_get
                device_req[:var] = message['var']

              when "set"
                device_req[:type] = :state_get
                device_req[:var] = message['var']
                
              when "command"
                device_req[:type] = :state_get
                device_req[:command] = message['name']
                device_req[:args] = message['args']
              end

              deferrable = EM::DefaultDeferrable.new
              deferrable.callback {|msg|

                if msg['success']
                  response = {'id' => msg['id'], 'success' => true}.to_json
                else
                  response = {'id' => msg['id'], 'success' => false}.to_json
                end
                
                ws.send response
              }

              @deferred_responses[device_req[:id]] = deferrable
              @amq.queue("roomtrol:dqueue:#{device}").publish(device_req.to_json)
              
            rescue JSON::ParserError, TypeError
              DaemonKit.logger.debug "Invalid JSON message from #{ws.signature}: #{message}"
            end
              
          end

          ws.onclose do
            @update_channel.unsubscribe(sid)
            DaemonKit.logger.debug "Connection on #{ws.signature} closed"
          end

          ws.onerror do
            DaemonKit.logger.debug "Error on #{ws.signature}"
          end

          
        end
      end
    end
  end
end

