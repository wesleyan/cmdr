require 'rubygems'
require 'em-websocket'
require 'json'
require 'mq'
require 'couchrest'
require 'state_machine'
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
  # - projector
  #   - **state** (on/off/warming/cooling)
  #   - **video_mute** (true/false)
  # - volume
  #   - **level** (0-1.0)
  #   - **mute** (true/false)
  # - source
  #   - **current** (source name)
  #   - **list** (array of source names)
  #
  # ###state_set
  # Sets the state of a variable
  #
  #     {
  #       "id": "D62F993B-E036-417C-948B-FEA389480984",
  #       "type": "state_set",
  #       "resource": "projector",
  #       "var": "power",
  #       "value": true
  #     }
  #
  # This will produce an ACK, which lets the client know that the request
  # was received.
  #
  #     {
  #       "id": "D62F993B-E036-417C-948B-FEA389480984",
  #       "ack": true
  #     }
  #
  # In order to know if this was successful, the client must wait for a
  # change in the variable (power, in this case) and ensure that it has
  # become the expected value.
  #
  # The allowed resource/var pairs are:
  #
  # - projector
  #   - **power** (true/false)
  #   - **mute** (true/false)
  # - volume
  #   - **level** (0-1.0)
  #   - **mute** (true/false)
  # - source
  #   - **current** (string name of a source)
  #
  # ###command
  # Executes a command
  #
  #     {
  #       "id": "D62F993B-E036-417C-948B-FEA389481512",
  #       "type": "command",
  #       "resource": "IREmitter",
  #       "name": "send_command",
  #       "args": ["play"]
  #     }
  #
  # This will also produce an ACK, as above.
  #
  # ## Server -> Client
  # ### connected
  # When a client connects, the server sends it a bunch of useful information
  # for setting itself up. The message looks like this:
  #
  #    {
  #      "id": "AEF80ED8-35C6-4EBC-B80C-218C306CA393",
  #      "type": "connection",
  #      "building": "Albritton",
  #      "room": "004",
  #      "sources": [
  #        {
  #         "name": "Laptop",
  #         "icon": "Laptop.png"
  #        }
  #      ],
  #      "actions": [
  #        {
  #          "name": "Play DVD",
  #          "prompt_projector": true,
  #          "source: "DVD"
  #        }
  #      ]
  #    }
  #
  # ### state_changed
  #
  #    {
  #      "id": "AEF80ED8-35C6-4EBC-B80C-218C306CA441",
  #      "type": "state_changed",
  #      "resource": projector,
  #      "var": "state",
  #      "old": "cooling",
  #      "new": "off"
  #    }
  class RoomtrolWebsocket
    # How long to wait for responses from the daemon
    TIMEOUT = 4.0
    # The resources that can be accessed
    RESOURCES = ["projector", "volume", "source", "ir_emitter"]
    
    def initialize
      @db = CouchRest.database("http://localhost:5984/rooms")

      @room = @db.get("_design/room").
        view("by_mac", {:key => MAC.addr})['rows'][0]['value']

      @devices = @db.get('_design/room').
        view('devices_for_room', {:key => @room['_id']})['rows'].
        map{|x| x['value']}

      @building = @db.get(@room['belongs_to'])['attributes']['name']

      @sources = @db.get('_design/wescontrol_web').
        view('sources', {:key => @room['_id']})['rows'].
        map{|x| x['value']}
        
      @actions = @db.get('_design/wescontrol_web').
        view('actions', {:key => @room['_id']})['rows'].
        map{|x| x['value']}
          
      @room_name = @room['attributes']['name']
      @projector = @room['attributes']['projector']
      @switcher = @room['attributes']['switcher']
      @ir_emitter = @room['attributes']['dvdplayer']
      @volume = @room['attributes']['volume']

      @devices_by_id = {}
      {@projector => "projector",
        @switcher => "switcher",
        @ir_emitter => "ir_emitter",
        @volume => "volume"
      }.each do |k, v|
        puts k
        d = @devices.find {|d| d['attributes']['name'] == k}
        @devices_by_id[d['_id']] = v if d
      end

      @source_fsm = make_state_machine(@sources).new(self)
    end

    # Starts the websockets server. This is a blocking call if run
    # outside of an EventMachine reactor.
    def run
      AMQP.start(:host => "localhost") do
        @mq = MQ.new
        @update_channel = EM::Channel.new
        @deferred_responses = {}

        @queue_name = "roomtrol:websocket:#{self.object_id}"
        @queue = @mq.queue(@queue_name)
        
        # watch for responses from devices
        @queue.subscribe{|json|
          msg = JSON.parse(json)
          puts "Got response: #{msg}"
          if @deferred_responses[msg["id"]]
            @deferred_responses.delete(msg["id"]).succeed(msg)
          end
        }

        topic = @mq.topic(EVENT_TOPIC)
        @mq.queue("roomtrol:websocket:#{self.object_id}:response").bind(topic, :key => "device.*").subscribe do |json|
          puts "Got event: #{json}"
          handle_event json
        end

        EM::WebSocket.start({
                              :host => "0.0.0.0",
                              :port => 8000,
                              :debug => true
                              #:secure => true  
                            }) do |ws|

          ws.onopen { onopen ws }

          ws.onmessage {|json| onmessage ws, json}
          
          ws.onclose do
            @update_channel.unsubscribe(@sid) if @sid
            DaemonKit.logger.debug "Connection on #{ws.signature} closed"
          end

          ws.onerror do
            DaemonKit.logger.debug "Error on #{ws.signature}"
          end
        end
      end
      
      def handle_event json
        msg = JSON.parse(json)
        if msg['state_update'] && msg['var'] && msg['now'] && msg['device']
          resource = @devices_by_id[msg['device']]
          if resource
            send_update resource, msg['var'], msg['was'], msg['now']
            case resource
            when "projector"
              @source_fsm.send("projector_to_#{msg['now']}") rescue nil
            when "switcher"
              @source_fms.send("switcher_to_#{msg['now']}") rescue nil
            end
          end
        end
      end

      def send_update resource, var, old, new
        update_msg = {
          'id' => UUIDTools::UUID.random_create.to_s,
          'type' => 'state_changed',
          'resource' => resource,
          'var' => var,
          'old' => old,
          'new' => new
        }
        @update_channel.push(update_msg)        
      end
      
      def onopen ws
        @sid = @update_channel.subscribe { |msg|
          DaemonKit.logger.debug "State update: #{msg}"
          ws.send msg
        }

        init_message = {
          'id' => UUIDTools::UUID.random_create.to_s,
          'type' => 'connection',
          'building' => @building,
          'room' => @room_name,
          'sources' => @sources.map{|source|
            {
              :id => source['_id'],
              :name => source['name'],
              :icon => source['icon']
            }
          },
          'actions' => @actions
        }

        ws.send init_message.to_json
      end

      def onmessage ws, json
        begin
          msg = JSON.parse(json)

          puts "Got message: #{msg.inspect}"

          deferrable = EM::DefaultDeferrable.new
          deferrable.callback {|resp|
            resp['id'] = msg['id']
            ws.send resp.to_json
          }
          deferrable.timeout TIMEOUT
          
          case msg['type']
          when "state_get" then state_get msg, deferrable
          when "state_set" then state_set msg, deferrable
          when "command" then command msg, deferrable
          else df.deferrable.succeed({:error => "Invalid message type"})
          end
          
        rescue JSON::ParserError, TypeError
          DaemonKit.logger.debug "Invalid JSON message from #{ws.signature}: #{json}"
        end
      end
      
      def state_get req, df
        state_action req, df, "get"
      end

      def state_set req, df
        state_action req, df, "set"
      end
      
      def state_action req, df, action
        if RESOURCES.include? req['resource']
          self.send "handle_#{req['resource']}_#{action}", req, df
        else
          df.succeed({:error => "Invalid resource"})
        end
      end

      def daemon_get var, device, df
        device_req = {
          :id => UUIDTools::UUID.random_create.to_s,
          :queue => @queue_name,
          :type => :state_get,
          :var => var
        }
        deferrable = EM::DefaultDeferrable.new
        deferrable.timeout TIMEOUT
        deferrable.callback {|result|
          df.succeed({:result => result})
        }
        deferrable.errback {|error|
          df.succeed({:error => error})
        }
        defer_device_operation device_req, device, df
      end

      def daemon_set var, value, device, df
        device_req = {
          :id => UUIDTools::UUID.random_create.to_s,
          :queue => @queue_name,
          :type => :state_set,
          :var => var,
          :value => value
        }
        deferrable = EM::DefaultDeferrable.new
        deferrable.timeout TIMEOUT
        deferrable.callback {|result|
          df.succeed({:ack => true})
        }
        deferrable.errback {|error|
          df.succeed({:error => error})
        }
        defer_device_operation device_req, device, deferrable
      end

      def set_projector_state state, df = EM::DefaultDeferrable
        daemon_set :input, state, @projector, df
      end

      def set_switcher_state state, df = EM::DefaultDeferrable
        daemon_set :input, state, @switcher, df
      end
      
      def defer_device_operation device_req, device, df        
        @deferred_responses[device_req[:id]] = df
        @mq.queue("roomtrol:dqueue:#{device}").publish(device_req.to_json)
      end

      ##################### Client code ####################

      def handle_projector_get req, df
        daemon_get req['var'], @projector, df
      end

      def handle_projector_set req, df
        daemon_set req['var'], req['value'], @projector, df
      end

      def handle_ir_emitter_get req, df
        daemon_get req['var'], @ir_emitter, df
      end

      def handle_volume_get req, df
        daemon_get req['var'], @volume, df
      end

      def handle_volume_set req, df
        daemon_set req['var'], req['value'], @volume, df
      end
      
      def handle_source_get req, df
        df.succeed({:result => @source_fsm.source})
      end

      def handle_source_set req, df
        @source_fsm.source = req['value']
        df.succeed({:ack => true})
      end
    end
    
    def make_state_machine sources
      klass = Class.new
      klass.class_eval do
        def initialize parent
          @parent = parent
          super
        end

        state_machine :source do
          after_transition any => any do |fsm, transition|
            @parent.send_update :source, nil, transition.from, transition.to 
          end
          sources.each do |source|
            this_state = source['name'].to_sym
            if p = source['input']['projector']
              if !@switcher
                event "projector_to_#{p}".to_sym do
                  transition all => this_state
                end
              end
              after_transition any => this_state do
                @parent.set_projector_state p
              end
            end
            if s = source['input']['switcher']
              if @switcher
                event "switcher_to_#{s}" do
                  transition all => this_state
                  @parent.set_projector_state p if p = source['input']['project']
                end
              end
              after_transition any => this_state do
                @parent.set_switcher_state s
              end
            end
          end
        end
      end
      klass
    end
  end
end
