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
  # ###State get requests
  # Gets information about the current state of elements in the system. Requests
  # look like this:
  #
  #     {
  #       "id": "DD2297B4-6982-4804-976A-AEA868564DF3",
  #       "type": "state_get",
  #       "resource": "projector",
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
  # The allowed resource/var pairs are listed here:
  #
  #  - projector
  #    - **state** (on/off/warming/cooling)
  #    - **video_mute** (true/false)
  #  - volume
  #    - **level** (0-1.0)
  #    - **mute** (true/false)
  #  - source
  #    - **current** (source name)
  #    - **list** (array of source names)
  #
  # ###state_set
  # Sets the state of a variable
  #
  #     {
  #        "id": "D62F993B-E036-417C-948B-FEA389480984",
  #        "type": "state_set",
  #        "resource": "projector",
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
  # The allowed resource/var pairs are:
  #
  #  - projector
  #    - **power** (true/false)
  #    - **mute** (true/false)
  #  - volume
  #    - **level** (0-1.0)
  #    - **mute** (true/false)
  #  - source
  #    - **current** (string name of a source)
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
  #       "building": "Albritton",
  #       "room": "004",
  #       "sources": [
  #         {
  #           "name": "Laptop",
  #           "icon": "Laptop.png"
  #         }
  #       ],
  #       "actions": [
  #         {
  #           "name": "Play DVD",
  #           "prompt_projector": true,
  #           "source: "DVD"
  #         }
  #       ]
  #     }
  #
  # ### state_changed
  #
  #     {
  #       "id": "AEF80ED8-35C6-4EBC-B80C-218C306CA441",
  #       "type": "state_changed",
  #       "resource": projector,
  #       "var": "state",
  #       "old": "cooling",
  #       "new": "off"
  #     }
  class WescontrolWebsocket
    def initialize
      @connections = {}
      @old_connections = {}
    end

    def run
      AMQP.start(:host => "localhost") do
        @mq = MQ.new
        
        EM::WebSocket.start(:host => "0.0.0.0", :port => 8000) do |ws|
          ws.onopen do
            DaemonKit.logger.debug "New connection on #{ws.signature}"
            
          end

          ws.onmessage do |json|
            message = JSON.parse(json)
          end

          ws.onclose do
            
          end
        end
      end
    end
  end
end
