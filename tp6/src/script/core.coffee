slinky_require('main.coffee')
slinky_require('models/device_model.coffee')
slinky_require('models/action_model.coffee')
slinky_require('models/room_model.coffee')
slinky_require('models/source_model.coffee')
slinky_require('server.coffee')

window.Tp.devices =
  projector: new Tp.Device {name: "projector"}
  volume: new Tp.Device {name: "volume"}
  ir_emitter: new Tp.Device {name: "ir_emitter"}
  blurayplayer: new Tp.Device {name: "blurayplayer"}
  computer: new Tp.Device {name: "computer"}

window.Tp.room = new Tp.Room

class RoomLabel
  updateRoomLabel: () ->
    building = Tp.room.get('building')
    name = Tp.room.get('name')
    #Tp.log(building + " " + name)
    $('#room-label').html(building + " " + name)
  bind: () ->
    Tp.room.bind 'change:building', this.updateRoomLabel
    Tp.room.bind 'change:name', this.updateRoomLabel

(new RoomLabel).bind()

class Clock
  start: () ->
    window.setInterval this.updateClock, 1000
  updateClock: () ->
    # Why can't JS have proper date formatting built in? Or printf?
    d = new Date
    hours = d.getHours()
    minutes = d.getMinutes()
    meridian = "AM"
    if hours > 11
      hours = hours-12
      meridian = "PM"

    hours = 12 if hours == 0
    if minutes < 10
      minutes = "0" + minutes

    $("#time-label").html(hours + ":" + minutes + " " + meridian)

(new Clock).start()

window.Tp.server = new Tp.Server

# Prevent dragging of images. Wait a little while for stuff to load
$(document).ready (() ->
  $('img').mousedown (event) -> event.preventDefault())
