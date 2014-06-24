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
  var Clock, RoomLabel;

  window.Tp.devices = {
    projector: new Tp.Device({
      name: "projector"
    }),
    volume: new Tp.Device({
      name: "volume"
    }),
    ir_emitter: new Tp.Device({
      name: "ir_emitter"
    }),
    blurayplayer: new Tp.Device({
      name: "blurayplayer"
    }),
    computer: new Tp.Device({
      name: "computer"
    })
  };

  window.Tp.room = new Tp.Room;

  RoomLabel = (function() {
    function RoomLabel() {}

    RoomLabel.prototype.updateRoomLabel = function() {
      var building, name;
      building = Tp.room.get('building');
      name = Tp.room.get('name');
      $('#location > p').html(building.slice(0,4) + " " + name);
      return $('#location > p').html(building.slice(0,4) + " " + name);
    };

    RoomLabel.prototype.bind = function() {
      Tp.room.bind('change:building', this.updateRoomLabel);
      return Tp.room.bind('change:name', this.updateRoomLabel);
    };

    return RoomLabel;

  })();

  (new RoomLabel).bind();

  Clock = (function() {
    function Clock() {}

    Clock.prototype.start = function() {
      return window.setInterval(this.updateClock, 1000);
    };

    Clock.prototype.updateClock = function() {
      var d, hours, meridian, minutes;
      d = new Date;
      hours = d.getHours();
      minutes = d.getMinutes();
      meridian = "AM";
      if (hours > 11) {
        hours = hours - 12;
        meridian = "PM";
      }
      if (hours === 0) {
        hours = 12;
      }
      if (minutes < 10) {
        minutes = "0" + minutes;
      }
      return $("#time-label").html(hours + ":" + minutes + " " + meridian);
    };

    return Clock;

  })();

  (new Clock).start();

  window.Tp.server = new Tp.Server;

  $(document).ready((function() {
    return $('img').mousedown(function(event) {
      return event.preventDefault();
    });
  }));

}).call(this);
