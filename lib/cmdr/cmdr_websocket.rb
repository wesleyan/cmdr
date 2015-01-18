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

require 'rubygems'
require 'em-websocket'
require 'json'
require 'mq'
require 'couchrest'
require 'state_machine'
require 'cmdr/authenticate'
module Cmdr
  # Cmdr websocket server. Used to provide better interactivity to
  # the touchscreen interface. Communication is through JSON, like for
  # Cmdr HTTP. Due to the nature of web sockets, message can either
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
  #      "room": "Allbritton 004",
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
  class CmdrWebsocket
    attr_reader :rooms
    
    # How long to wait for responses from the daemon
    TIMEOUT = 4.0
    # The resource names for devices
    DEVICES = {
      "projector"  => ["power", "video_mute", "state", "video_mute", "timer"],
      "volume"     => ["volume", "mute"],
      "switcher"   => ["video", "audio"],
      "blurayplayer" => ["play", "pause", "forward", "back", "stop", "eject", "next", "previous", "title", "menu", "up", "down", "left", "right", "enter"],
      "ir_emitter" => [],
      "computer"   => ["reachable"],
      "mac"        => []
    }
    # The resources that can be accessed
    RESOURCES = DEVICES.merge({"source" => ["source"]})
    
 
    # THIS function has now been generalized to deal with multiple rooms, so every other function has to learn to work with the new room info structure
    def initialize
      @credentials = Authenticate.get_credentials
      @db = CouchRest.database("http://#{@credentials["user"]}:#{@credentials["password"]}@localhost:5984/rooms")
      @rooms = {}
      @db.get("_design/room").
        view("all_rooms")['rows'].map{|x| x['value']}.each do |room|
          id = room['_id']
          @rooms[id] = {}
          @rooms[id]['room'] = room
          devices = @db.get('_design/room').view('devices_for_room', {:key => id})['rows'].map{|x| x['value']}
          @rooms[id]['sources'] = @db.get('_design/cmdr_web').view('sources', {:key => id})['rows'].map{|x| x['value']}
          @rooms[id]['actions'] = @db.get('_design/cmdr_web').view('actions', {:key => id})['rows'].map{|x| x['value']}
          @rooms[id]['room_name'] = room['attributes']['name']
          devs = {}
          DEVICES.each do |r,_|
            devs[r] = room['attributes'][r]
          end
          @rooms[id]['devices'] = devs
          @rooms[id]['devices_by_id'] = {}
          @rooms[id]['device_record_by_resource'] = {}
          devs.each do |k,v|
            d = devices.find {|d| d['attributes']['name'] == v}
            if d
              @rooms[id]['devices_by_id'][d['_id']] ||= []
              @rooms[id]['devices_by_id'][d['_id']] << k
            end
            @rooms[id]['device_record_by_resource'][k] = d
          end
      end
    end

    # Starts the websockets server. This is a blocking call if run
    # outside of an EventMachine reactor.
    def run
      AMQP.start(:host => "localhost") {
        @mq = MQ.new
        @update_channel = EM::Channel.new
        @deferred_responses = {}

        @queue_name = "cmdr:websocket:#{self.object_id}"
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
        @mq.queue("cmdr:websocket:#{self.object_id}:response").bind(topic, :key => "device.*").subscribe do |json|
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
      @rooms.keys.each do |room_id|
	# get the initial source
        room = @rooms[room_id]
	proj = room['device_record_by_resource']['projector']
	switch = room['device_record_by_resource']['switcher']

	p_input = proj['attributes']['state_vars']['input']['state'] rescue nil
	v_input = switch['attributes']['state_vars']['video']['state'] rescue nil
	a_input = switch['attributes']['state_vars']['audio']['state'] rescue nil
	s_input = switch['attributes']['state_vars']['input']['state'] rescue nil

	p_src = (room['sources'].find {|s| s['input']['projector'] == p_input})['name'] rescue nil
	v_src = (room['sources'].find {|s| s['input']['video'] == v_input})['name'] rescue nil
	a_src = (room['sources'].find {|s| s['input']['audio'] == a_input})['name'] rescue nil
	s_src = (room['sources'].find {|s| s['input']['switcher'] == s_input})['name'] rescue nil

	if initial_source = (v_src || p_src || a_src || s_src || (room['sources'][0] && room['sources'][0]['name']))
	  DaemonKit.logger.debug("Initial source: #{initial_source}")
	  # For some reason, when we define events in make_state_machine
	  # the events also get fired. This is highly undesireable. This
	  # is just a hack that ignores the commands to switch until the
	  # thing is defined.
	  room['dont_switch'] = true
	  room['source_fsm'] = make_state_machine(self, room, initial_source.to_sym).new
	  room['dont_switch'] = false
	  # TODO: Reconsider this line. Commenting it out fixes an issue
	  # where the projector flashes when the daemon starts, but
	  # maybe isn't ideal? I'm not really sure.
	  # @source_fsm.send("select_#{initial_source}")
	end
      end
    end
    
    def handle_event json
      msg = JSON.parse(json)
      DaemonKit.logger.debug(msg.inspect)
      room = @rooms[msg['room']]
      if msg['state_update'] && msg['var'] && !msg['now'].nil? && msg['device']
        resource = (room['devices_by_id'][msg['device']] || {}).find {|r|
          RESOURCES[r].include? msg['var']
        }
        unless resource.nil?
          DaemonKit.logger.debug("Setting FSM: #{resource}, #{msg['var']}")
          send_update room, resource, msg['var'], msg['was'], msg['now']
          case [resource, msg['var']]
          when ["projector", "input"]
            room['source_fsm'].send("projector_to_#{msg['now']}") rescue nil
          when ["video", "input"]
            room['source_fms'].send("switcher_to_#{msg['now']}") rescue nil
          when ["audio", "input"]
            room['source_fms'].send("switcher_to_#{msg['now']}") rescue nil
          when ["switcher", "input"]
            room['source_fms'].send("switcher_to_#{msg['now']}") rescue nil
          end
        end
      end
    end

    def send_update room, resource, var, old, new
      DaemonKit.logger.debug([resource, var, old, new].inspect)
      update_msg = {
        'id' => UUIDTools::UUID.random_create.to_s,
        'room' => room['_id'],
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
      }

      ws.send init_message.to_json
    end
    # INSTEAD of sending the init message with everything,
    # the frontend needs to send a message with just the rooms in it
    # and an init type so we can send it the room details
    def send_init msg, df
      room = @rooms[msg['room']]
      init_message = {
        'id' => UUIDTools::UUID.random_create.to_s,
        'type' => :init,
        'room' => room['room_name'],
        'sources' => room['sources'].map{|source|
          {
            :id => source['_id'],
            :name => source['name'],
            :icon => source['icon'] || (source['name'] + '.png')
          }
        },
        'actions' => room['actions']
      }
      df.succeed(init_message)
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
        when "init" then send_init msg, deferrable
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
          :room => req['room'],
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

    def set_device_state dont_switch, device, state, input = :input, df = EM::DefaultDeferrable.new
      unless dont_switch
        DaemonKit.logger.debug "Setting #{device} input to #{state}"
        daemon_set input, state, device, df
      end
    end
    
    def defer_device_operation device_req, device, df        
      @deferred_responses[device_req[:id]] = df
      @mq.queue("cmdr:dqueue:#{device}").publish(device_req.to_json)
    end

    ##################### Client code ####################

    def handle_device_get req, df
      room = @rooms[req['room']]
      daemon_get req['var'], room['devices'][req['resource']], df
    end

    def handle_device_set req, df
      room = @rooms[req['room']]
      daemon_set req['var'], req['value'], room['devices'][req['resource']], df
    end
    
    def handle_source_get req, df
      room = @rooms[req['room']]
      if room['source_fsm']
        df.succeed({:result => room['source_fsm'].source})
      else
        df.succeed({:error => "No sources defined"})
      end
    end

    def handle_source_set req, df
      DaemonKit.logger.debug "setting source: #{req.inspect}"
      @rooms[req['room']]['source_fsm'].send "select_#{req['value']}" rescue nil
      df.succeed({:ack => true})
    end

    def make_state_machine parent, room, initial
      sources = room['sources']
      klass = Class.new
      klass.class_eval do
        state_machine :source, :initial => initial do
          after_transition any => any do |fsm, transition|
            DaemonKit.logger.debug "transitions from #{transition.from} to #{transition.to}"
            parent.send_update room, :source, :source, transition.from, transition.to 
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
                parent.set_device_state room['dont_switch'], room['devices']["projector"], p
              end
            end
            if v
              event "switcher_to_#{v}".to_sym do
                transition all => this_state
                parent.set_device_state room['dont_switch'], room['devices']["projector"], p
              end
              after_transition any => this_state do
                DaemonKit.logger.debug "VIDEO: Transitioned to #{this_state}, and #{v.inspect}"
                parent.set_device_state room['dont_switch'], room['devices']["switcher"], v, :video
              end
            end
            if a
              event "switcher_to_#{a}".to_sym do
                transition all => this_state
              end
              after_transition any => this_state do
                DaemonKit.logger.debug "AUDIO: Transitioned to #{this_state}, and #{a.inspect}"
                parent.set_device_state room['dont_switch'], room['devices']["switcher"], a, :audio 
              end
            end
            if s
              event "switcher_to_#{s}".to_sym do
                transition all => this_state
                parent.set_device_state room['dont_switch'], room['devices']["projector"], p
              end
              after_transition any => this_state do
                parent.set_device_state room['dont_switch'], room['devices']["switcher"], s
              end
            end
          end
        end
      end
      klass
    end
  end
end
