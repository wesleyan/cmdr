require 'rubygems'
require 'em-websocket'
require 'json'
require 'mq'
require 'couchrest'

# database at http://roomtrol-allb004.class.wesleyan.edu:5984

# # Wescontrol websocket server. Used to provide better interactivity to
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
# ###State get requests
# Gets information about the current state of elements in the system. Requests
# look like this:
#
# {
# "id": "DD2297B4-6982-4804-976A-AEA868564DF3",
# "type": "state_get",
# "resource": "projector",
# "var": "power"
# }
#
# This should produce the response:
#
# {
# "id": "DD2297B4-6982-4804-976A-AEA868564DF3",
# "result": true
# }
#
# The allowed resource/var pairs are listed here:
#
# - projector
# - **state** (on/off/warming/cooling)
# - **video_mute** (true/false)
# - volume
# - **level** (0-1.0)
# - **mute** (true/false)
# - source
# - **current** (source name)
# - **list** (array of source names)
#
# ###state_set
# Sets the state of a variable
#
# {
# "id": "D62F993B-E036-417C-948B-FEA389480984",
# "type": "state_set",
# "resource": "projector",
# "var": "power",
# "value": true
# }
#
# This will produce an ACK, which lets the client know that the request
# was received.
#
# {
# "id": "D62F993B-E036-417C-948B-FEA389480984",
# "ack": true
# }
#
# In order to know if this was successful, the client must wait for a
# change in the variable (power, in this case) and ensure that it has
# become the expected value.
#
# The allowed resource/var pairs are:
#
# - projector
# - **power** (true/false)
# - **mute** (true/false)
# - volume
# - **level** (0-1.0)
# - **mute** (true/false)
# - source
# - **current** (string name of a source)
#
# ###command
# Executes a command
#
# {
# "id": "D62F993B-E036-417C-948B-FEA389481512",
# "type": "command",
# "device": "IREmitter",
# "name": "send_command",
# "args": ["play"]
# }
#
# This will also produce an ACK, as above.
#
# ## Server -> Client
# ### connected
# When a client connects, the server sends it a bunch of useful information
# for setting itself up. The message looks like this:
#
# {
# "id": "AEF80ED8-35C6-4EBC-B80C-218C306CA393",
# "type": "connection",
# "building": "Albritton",
# "room": "004",
# "sources": [
# {
# "name": "Laptop",
# "icon": "Laptop.png"
# }
# ],
# "actions": [
# {
# "name": "Play DVD",
# "prompt_projector": true,
# "source: "DVD"
# }
# ]
# }
#
# ### state_changed
#
# {
# "id": "AEF80ED8-35C6-4EBC-B80C-218C306CA441",
# "type": "state_changed",
# "resource": projector,
# "var": "state",
# "old": "cooling",
# "new": "off"
# }
# 
# 


class WescontrolWebsocket
    def initialize
        @db = CouchRest.database(Wescontrol::DB_URI)
        @room = db.get("_design/room").view("by_mac", {:key => MAC.addr})['rows'][0]
        @projector = @room["attributes"]["projector"]
        @switcher = @room["attributes"]["switcher"]
        @dvdplayer = @room["attributes"]["dvdplayer"]
        @volume = @room["attributes"]["volume"]
    end

    def run
      AMQP.start(:host => "localhost") do
        @mq = MQ.new
        @update_channel = EM::Channel.new
        @deferred_responses = {}

        @queue_name = 'roomtrol:http:#{self.object_id}'
        @queue = @amq.queue(@queue_name)

        @queue.subscribe{ |json|
          msg = JSON.parse(json)

          if msg['state_update']
            # update the database?
            
            @update_channel.push(msg)

          else
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
              update_msg = {
                'id' => UUIDTools::UUID.random_create.to_s,
                'type' => 'state_changed'
                'var' => msg['var']
                'old' => msg['was']
                'new' => msg['now']
              }
              ws.send update_msg
            }

            # send the client the required
            # information about room, devices, etc.
            # to set it up
            
            init_message = {
              'id' => UUIDTools::UUID.random_create.to_s,
              'type' => 'connection'
              'building' => @room["attributes"]["building"]
              #'room' =>
              #'devices' =>
              #etc
            }

            ws.send init_message.to_json
              
          end

          ws.onmessage do |json|
            begin
              
              message = JSON.parse(json)
              
              resp = {'id' => message['id'], 'ack' => true}.to_json
              ws.send resp
            
              case message['type']
                
              when "state_get"
                response {'id' => message['id']}
                case message['resource']
                when "projector"
                  variable = message['var']
                  if variable in ['power', 'mute']
                    get_response['value'] = @projector[message['var']]
                  else
                    Daemonkit.logger.debug "Uknown projector variable #{variable}"
                  end
                    
                when "volume"
                  variable = message['var']
                  if variable in ['level', 'mute']
                    get_response['value'] = @volume[message['var']]
                  else
                    Daemonkit.logger.debug "Unknown volume variable #{variable}"
                  end
                    
                when "source"
                  variable = message['var']
                  if variable in ['current']
                    get_response['value'] = @room["attributes"]["current"]
                  else
                    Daemonkit.logger.debug "Uknown source variable #{variable}"
                  end 
                  
                else
                  Daemonkit.logger.debug "Unknown resource #{message['resource']}"
              
                ws.send get_response
                return
              end
                            
              device_req = {
                  :id => message['id'],
                  :queue => @queue_name
              }
                              
              when "state_set" 
                device_req[:type] = :state_set
                device_req[:var] = message['var']
                device_req[:value] = message['value']
              end
              
                                
              when "command"
                device[:type] = :command
                device[:method] = message['method']
                device[:args] = message['args']
              end

              deferrable = EM::DefaultDeferrable.new
              deferrable.callback {|msg|
                msg = JSON.parse(json)
                
                response = {
                  'id' => msg['id']
                }
                
                case msg['type']
                when 'state_get'
                  response['value'] = msg['value']
                when 'state_set'
                  if response['result']
                    
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
