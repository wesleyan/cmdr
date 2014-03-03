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
      return $('#room-label').html(building + " " + name);
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
