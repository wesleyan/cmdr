require 'rubygems'
require 'em-websocket'
require 'json'
require 'mq'
require 'couchrest'
require 'state_machine'
require 'roomtrol/authenticate'
module Wescontrol
  #This Wescontrol_websocket is for multi projector setups

  
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
  #   - **volume** (0-1.0)
  #   - **mute** (true/false)
  # - source
  #   - **current** (source name)
  #   - **list** (array of source names)
  # - computer
  #   - **reachable**
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
  #   - **volume** (0-1.0)
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
    attr_reader :devices
    
    # How long to wait for responses from the daemon
    TIMEOUT = 4.0
    # The resource names for devices
    DEVICES = {
      "projector1" => ["power", "video_mute", "state", "video_mute"],
      "projector2" => ["power", "video_mute", "state", "video_mute"],
      "projector3" => ["power", "video_mute", "state", "video_mute"],
      "volume"     => ["volume", "mute"],
      "switcher"   => ["video", "audio"],
      "blurayplayer" => ["play", "pause", "forward", "back", "stop", "eject", "next", "previous", "title", "menu", "up", "down", "left", "right", "enter"],
      "ir_emitter" => [],
      "computer"   => ["reachable"],
      "mac"        => []
    }
    # The resources that can be accessed
    RESOURCES = DEVICES.merge({"source" => ["source"]})
    
    def initialize
      @credentials = Authenticate.get_credentials
      @db = CouchRest.database("http://#{@credentials["user"]}:#{@credentials["password"]}@localhost:5984/rooms")

      @room = @db.get("_design/room").
        view("by_mac", {:key => MAC.addr})['rows'][0]['value']
      devices = @db.get('_design/room').
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
      
      @devices = {}
      
      DEVICES.each do |r, _|
        @devices[r] = @room['attributes'][r]
      end
      
      @devices_by_id = {}
      @device_record_by_resource = {}
      @devices.each do |k, v|
        d = devices.find {|d| d['attributes']['name'] == v} 
        if d
          @devices_by_id[d['_id']] ||= []
          @devices_by_id[d['_id']] << k
        end
        @device_record_by_resource[k] = d
      end
      #DaemonKit.logger.info "db = #{@db} \nROOM = #{@room}, \nDEVICES = #{devices}, \nBUILDING = #{@building}, \nSOURCES = #{@sources}, \nACTIONS = #{@actions}, \nROOMNAME = #{@room_name}, \n@DEVICES = #{@devices}"
    end

    # Starts the websockets server. This is a blocking call if run
    # outside of an EventMachine reactor.
    def run
      
      AMQP.start(:host => "localhost") {
        
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
          handle_event json
        end

        setup
        
        EM::WebSocket.start({

                              :host => "0.0.0.0",
                              :port => 8000,
                              :debug => false
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
      }
    end

    def setup
      # get the initial source
      proj1 = @device_record_by_resource['projector1']
      proj2 = @device_record_by_resource['projector2']
      proj3 = @device_record_by_resource['projector3']
      switch = @device_record_by_resource['switcher']

      p1_input = proj1['attributes']['state_vars']['input']['state'] rescue nil
			p2_input = proj2['attributes']['state_vars']['input']['state'] rescue nil
      p3_input = proj3['attributes']['state_vars']['input']['state'] rescue nil
      v_input = switch['attributes']['state_vars']['video']['state'] rescue nil
      a_input = switch['attributes']['state_vars']['audio']['state'] rescue nil
      s_input = switch['attributes']['state_vars']['input']['state'] rescue nil

      p1_src = (@sources.find {|s| s['input']['projector'] == p1_input})['name'] rescue nil
      p2_src = (@sources.find {|s| s['input']['projector'] == p2_input})['name'] rescue nil
      p3_src = (@sources.find {|s| s['input']['projector'] == p3_input})['name'] rescue nil
      v_src = (@sources.find {|s| s['input']['video'] == v_input})['name'] rescue nil
      a_src = (@sources.find {|s| s['input']['audio'] == a_input})['name'] rescue nil
      s_src = (@sources.find {|s| s['input']['switcher'] == s_input})['name'] rescue nil

      if initial_source = (v_src || p1_src || p2_src || p3_src || a_src || s_src || @sources[0]['name'])
        DaemonKit.logger.debug("Initial source: #{initial_source}")
        # For some reason, when we define events in make_state_machine
        # the events also get fired. This is highly undesireable. This
        # is just a hack that ignores the commands to switch until the
        # thing is defined.
        @dont_switch = true
        @source_fsm1 = make_state_machine(self, @sources, initial_source.to_sym, "1").new
        @source_fsm2 = make_state_machine(self, @sources, initial_source.to_sym, "2").new
        @source_fsm3 = make_state_machine(self, @sources, initial_source.to_sym, "3").new
        @dont_switch = false
        # TODO: Reconsider this line. Commenting it out fixes an issue
        # where the projector flashes when the daemon starts, but
        # maybe isn't ideal? I'm not really sure.
        # @source_fsm.send("select_#{initial_source}")
      end
    end
    
    def handle_event json
      msg = JSON.parse(json)
      DaemonKit.logger.debug(msg.inspect)
      if msg['state_update'] && msg['var'] && !msg['now'].nil? && msg['device']
        resource = (@devices_by_id[msg['device']] || {}).find {|r|
          RESOURCES[r].include? msg['var']
        }
        unless resource.nil?
          DaemonKit.logger.debug("Setting FSM: #{resource}, #{msg['var']}")
          send_update resource, msg['var'], msg['was'], msg['now']
          case [resource, msg['var']]
          when ["projector1", "input"]
            DaemonKit.logger.info "projector 1 recevived a message to #{msg['now']}"
            @source_fsm1.send("projector_to_#{msg['now']}") rescue nil
          when ["projector2", "input"]
            @source_fsm2.send("projector_to_#{msg['now']}") rescue nil
          when ["projector3", "input"]
            @source_fsm3.send("projector_to_#{msg['now']}") rescue nil
          when ["video", "input"]
            @source_fms.send("switcher_to_#{msg['now']}") rescue nil
          when ["audio", "input"]
            @source_fms.send("switcher_to_#{msg['now']}") rescue nil
          when ["switcher", "input"]
            @source_fms.send("switcher_to_#{msg['now']}") rescue nil
          end
        end
      end
    end

    def send_update resource, var, old, new
      DaemonKit.logger.debug([resource, var, old, new].inspect)
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
        ws.send msg.to_json
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
            :icon => source['icon'] || (source['name'] + '.png')
          }
        },
        'actions' => @actions
      }

      ws.send init_message.to_json
    end

    def onmessage ws, json
      begin
        msg = JSON.parse(json)

        deferrable = EM::DefaultDeferrable.new
        deferrable.callback {|resp|
          resp['id'] = msg['id']
          ws.send resp.to_json
        }
        deferrable.timeout TIMEOUT
        
        case msg['type']
        when "state_get" then state_action msg, deferrable, :get
        when "state_set" then state_action msg, deferrable, :set
        when "command" then command msg, deferrable
        else df.deferrable.succeed({:error => "Invalid message type"})
        end
        
      rescue JSON::ParserError, TypeError
        DaemonKit.logger.debug "Invalid JSON message from #{ws.signature}: #{json}"
      end
    end
    
    def state_action req, df, action
      if (DEVICES[req['resource']] || []).include?(req['var'])
        self.send "handle_device_#{action}", req, df
      elsif req['resource'] == "source"
        self.send "handle_source_#{action}", req, df
      else
        df.succeed({:error => "Invalid resource"})
      end
    end

    def command req, df
      if (DEVICES[req['resource']] || []).include?(req['var'])
        device = req['resource']
        device_req = {
          :id => UUIDTools::UUID.random_create.to_s,
          :queue => @queue_name,
          :type => :command,
          :method => req['method'],
          :args => req['args']
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

    def daemon_set var, value, device, df = EM::DefaultDeferrable.new
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

    def set_device_state device, state, input = :input, df = EM::DefaultDeferrable.new
      unless @dont_switch
        DaemonKit.logger.debug "Setting #{device} #{input} to #{state}"
        daemon_set input, state, device, df
      end
    end
    
    def defer_device_operation device_req, device, df        
      @deferred_responses[device_req[:id]] = df
      @mq.queue("roomtrol:dqueue:#{device}").publish(device_req.to_json)
    end

    ##################### Client code ####################

    def handle_device_get req, df
      daemon_get req['var'], @devices[req['resource']], df
    end

    def handle_device_set req, df
      daemon_set req['var'], req['value'], @devices[req['resource']], df
    end
    
    def handle_source_get req, df
      case req['var']
      when "source1"
        if @source_fsm1
          df.succeed({:result => @source_fsm1.source, :var => req['var']})
        else
          df.succeed({:error => "No sources defined"})
        end
      when "source2"
        if @source_fsm2
          df.succeed({:result => @source_fsm2.source, :var => req['var']})
        else
          df.succeed({:error => "No sources defined"})
        end
      when "source3"
        if @source_fsm3
          df.succeed({:result => @source_fsm3.source, :var => req['var']})
        else
          df.succeed({:error => "No sources defined"})
        end
      end
    end

    def handle_source_set req, df
      projectors = req['projectors']
      #case req['var']
      #when "source1"
      #if projectors[0] == 1
      DaemonKit.logger.debug "received source set request: #{req.inspect}"
      if projectors[0]
        DaemonKit.logger.debug "setting source on projector 1: #{req.inspect}"
        @source_fsm1.send "select_#{req['value']}" rescue nil
        df.succeed({:ack => true})
      end
      #when "source2"
      if projectors[1]
        DaemonKit.logger.debug "setting source on projector 2: #{req.inspect}"
        @source_fsm2.send "select_#{req['value']}" rescue nil
        df.succeed({:ack => true})
      end
      #when "source3"
      if projectors[2]
        DaemonKit.logger.debug "setting source on projector 3: #{req.inspect}"
        @source_fsm3.send "select_#{req['value']}" rescue nil
        df.succeed({:ack => true})
      end
      #end
    end

    def make_state_machine parent, sources, initial, proj = ""
      klass = Class.new
      klass.class_eval do
        state_machine :source, :initial => initial do
          after_transition any => any do |fsm, transition|
            DaemonKit.logger.debug "transitions from #{transition.from} to #{transition.to}"
            parent.send_update :source, "source#{proj}".to_sym, transition.from, transition.to 
          end
          sources.each do |source|
            this_state = source['name'].to_sym
            event "select_#{this_state}".to_sym do
              # begin
              #   1/0
              # rescue => e
              #   DaemonKit.logger.debug e.backtrace.join("\n")
              # end

              transition all => this_state
            end
            p = source['input']['projector']
            v = source['input']['video']
            a = source['input']['audio']
            s = source['input']['switcher']
            if p
              if !source['input']['switcher']
                event "projector_to_#{p}".to_sym do
                  transition all => this_state
                end
              end
              after_transition any => this_state do
                DaemonKit.logger.debug "Transitioned to #{this_state}, and #{p.inspect}"
                parent.set_device_state parent.devices["projector#{proj}"], p
              end
            end
            if v
              event "switcher_to_#{v}" do
                transition all => this_state
                parent.set_device_state parent.devices["projector#{proj}"], p
              end
              after_transition any => this_state do
                DaemonKit.logger.debug "VIDEO: Transitioned to #{this_state}, and #{v.inspect}"
                DaemonKit.logger.debug "Switching projector #{proj} to video #{v}"
                parent.set_device_state parent.devices["switcher"], [v,proj.to_i], :video
              end
            end
            if a
              event "switcher_to_#{a}" do
                transition all => this_state
              end
              after_transition any => this_state do
                DaemonKit.logger.debug "AUDIO: Transitioned to #{this_state}, and #{a.inspect}"
                DaemonKit.logger.debug "Switching projector #{proj} to audio #{v}"
                parent.set_device_state parent.devices["switcher"], [a,proj.to_i], :audio 
              end
            end
            if s
              event "switcher_to_#{s}" do
                transition all => this_state
                parent.set_device_state parent.devices["projector#{proj}"], p
              end
              after_transition any => this_state do
                parent.set_device_state parent.devices["switcher"], [s,proj.to_i]
              end
            end
          end
        end
      end
      klass
    end
  end
end
