/**
 * Copyright (C) 2014 Wesleyan University
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

(function() {
  // So we can parse out the room id.
  function parse(val) {
    var result = "Not found",
        tmp = [];
    location.search
    //.replace ( "?", "" ) 
    // this is better, there might be a question mark inside
    .substr(1)
        .split("&")
        .forEach(function (item) {
        tmp = item.split("=");
        if (tmp[0] === val) result = decodeURIComponent(tmp[1]);
    });
    return result;
  }
  
  var Server;

  Server = (function() {
    function Server() {
      var _this = this;
      this.websock = new Tp.Websock();
      this.websock.bind("message", function(msg) {
        return _this.handle_msg(msg);
      });
      this.websock.bind("disconnected", function() {
        return $('#lost-connection').show();
      });
      this.websock.bind("connected", function() {
        return $('#lost-connection').hide();
      });
      this.websock.bind("connecting", function() {
        $('#lost-connection .reconnection-attempt').hide();
        return $('#lost-connection .reconnecting').show();
      });
      this.websock.bind("reconnect_failed", function() {
        $('#lost-connection .reconnection-attempt').show();
        return $('#lost-connection .reconnecting').hide();
      });
      this.websock.bind("reconnecting", function(msg) {
        var attempts, delay, reconnection_time;
        delay = msg[0], attempts = msg[1];
        reconnection_time = new Date(Date.now() + delay);
        if (_this.reconnection_msg_timer) {
          clearInterval(_this.reconnection_msg_timer);
        }
        return _this.reconnection_msg_timer = setInterval((function() {
          var seconds;
          seconds = Math.round((reconnection_time - Date.now()) / 1000);
          return $('#lost-connection .reconnection-counter').html(seconds + " seconds");
        }), 500);
      });
      this.bind('state_set', function(msg) {
        msg['type'] = 'state_set';
        return _this.send_message(msg);
      });
      this.bind('command', function(msg) {
        msg['type'] = 'command';
        return _this.send_message(msg);
      });
      this.requests = {};
      $(window).load(function() {
        return _this.websock.connect();
      });
    }
    Server.prototype.connected = function(msg) {
      return this.send_message({ 'type': 'init' });
    }
    Server.prototype.init = function(msg) {
      var room_name;
      Tp.sources.refresh([]);
      Tp.actions.refresh([]);
      room_name = msg.room;
      Tp.room.set({ 'name': room_name });
      Tp.sources.add(_.map(msg.sources, function(x) {
        return {
          id: x.id,
          name: x.name,
          icon: x.icon
        };
      }));
      Tp.actions.add(_.map(msg.actions, function(x) {
        var _ref, _ref1, _ref2;
        return {
          id: x._id,
          name: x.name,
          source: Tp.sources.get((_ref = x.settings) != null ? _ref.source : void 0),
          prompt_projector: (_ref1 = x.settings) != null ? _ref1.prompt_projector : void 0,
          module: (_ref2 = x.settings) != null ? _ref2.module : void 0
        };
      }));
      this.state_get("projector", "state");
      this.state_get("projector", "video_mute");
      this.state_get("volume", "volume");
      this.state_get("volume", "mute");
      this.state_get("source", "source");
      return $('img').mousedown(function(event) {
        return event.preventDefault();
      });
    };

    Server.prototype.send_message = function(msg) {
      msg['id'] = this.createUUID();
      msg['room'] = parse('room_id');
      this.websock.send(JSON.stringify(msg));
      return msg['id'];
    };

    Server.prototype.handle_msg = function(json) {
      var msg;
      msg = JSON.parse(json);
      console.log(msg);
      switch (msg.type) {
        case "init":
          return this.init(msg);
        case "connection":
          return this.connected(msg);
        case "state_changed":
          if (msg['room'] === parse('room_id')) {
	    if (msg['resource'] === 'source') {
	      return this.source_changed(msg);
	    } else {
	      return this.device_changed(msg);
	    }
          }
          break;
        case "ack":
          return "Got ack";
        default:
          if (this.requests[msg['id']]) {
            this.requests[msg['id']](msg);
            return delete this.requests[msg['id']];
          } else {
            return Tp.log("Unhandled WS message: " + event.data);
          }
      }
    };

    Server.prototype.source_changed = function(msg) {
      var name, state;
      name = msg['new'] || msg['result'];
      state = Tp.sources.find(function(s) {
        return s.get('name') === name;
      });
      return Tp.room.set({
        source: state
      });
    };

    Server.prototype.device_changed = function(msg) {
      var device, hash;
      device = Tp.devices[msg['resource']];
      Tp.log("Device changed");
      Tp.log(device);
      hash = {};
      hash[msg['var']] = msg['new'];
      Tp.log(hash);
      return device.set(hash);
    };

    Server.prototype.state_get = function(resource, variable, callback) {
      var id,
        _this = this;
      id = this.send_message({
        type: "state_get",
        resource: resource,
        "var": variable
      });
      return this.requests[id] = function(msg) {
        var hash;
        if (msg['result'] === null) {
          return;
        }
        switch (resource) {
          case 'source':
            return _this.source_changed(msg);
          default:
            hash = {};
            Tp.log("Setting %s, %s to %s", resource, variable, msg['result']);
            hash[variable] = msg['result'];
            return Tp.devices[resource].set(hash);
        }
      };
    };

    Server.prototype.createUUID = function() {
      var hexDigits, i, s, _i;
      s = [];
      hexDigits = "0123456789ABCDEF";
      for (i = _i = 0; _i <= 31; i = ++_i) {
        s[i] = hexDigits.substr(Math.floor(Math.random() * 0x10), 1);
      }
      s[12] = "4";
      s[16] = hexDigits.substr((s[16] & 0x3) | 0x8, 1);
      return s.join("");
    };

    return Server;

  })();

  _.extend(Server.prototype, Backbone.Events);

  Tp.Server = Server;

}).call(this);
