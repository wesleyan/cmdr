slinky_require('main.coffee')

# Stub out Backbone.sync, as we're doing all out communication with
# the server over web sockets.
window.Backbone.sync = (method, model, success, error) ->
  true

# This code is largely inspired by Socket.io's client library
class Websock
  connected: no
  connecting: no
  should_reconnect: yes
  options:
    host: "ws://#{window.location.host}:8000/"
    connect_timeout: 5000
    reconnection_delay: 500
    max_reconnection_attempts: 10
    max_delay: 60

  websock_connect: ->
    @ws = new WebSocket(@options.host)

    @ws.onopen = (event) =>
      Tp.log "Connected to WS"
      this.trigger("connected")
      @connected = yes

    @ws.onmessage = (event) =>
      this.trigger("message", event.data)

    @ws.onclose = (event) =>
      this.trigger("disconnected")
      @disconnected()

  send: (msg) ->
    Tp.log("Sending: %s", msg)
    @ws.send(msg)

  connect: ->
    Tp.log("Connect!")
    if !@connected
      if @connecting then @disconnect()
      @websock_connect()
      @connect_timeout_timer = setTimeout (=>
        if !@connected
          @disconnect
          this.trigger("connection_failed")
          Tp.log("Could not connect")
      ), @connect_timeout

  reconnect: ->
    Tp.log("Reconnecting")
    @reconnecting = true
    @reconnection_attempts = 0
    @reconnection_delay = @options.reconnection_delay
    reset = () =>
      Tp.log("Resetting")
      if @connected then @trigger("reconnect", @reconnection_events)
      delete this.reconnecting
      delete this.reconnection_attempts
      delete this.reconnection_delay
      delete this.reconnection_timer

    maybe_reconnect = () =>
      if !@reconnecting then return
      if !@connected
        if @connecting && @reconnecting
          return @reconnection_timer = setTimeout(maybe_reconnect, 1000)
        if @reconnection_attempts++ >= @options.max_reconnection_attempts
          Tp.log("Reconnection failed")
          @trigger("reconnect_failed")
          reset()
        else
          @reconnection_delay *= 2
          max = @options.max_delay
          @reconnection_delay = max if @reconnection_delay > max
          @connect()
          @trigger("reconnecting", [@reconnection_delay, @reconnection_attempts])
          Tp.log("Reconnection delay: %d s", @reconnection_delay/1000)
          @reconnection_timer = setTimeout(maybe_reconnect, @reconnection_delay)
      else
        reset()
    @reconnection_timer = setTimeout(maybe_reconnect, @reconnection_delay)
    @bind("connect", maybe_reconnect)

  disconnect: ->
    if @connect_timeout_timer then clearTimeout @connect_timeout_timer
    if @ws then @ws.close()

  disconnected: ->
    @was_connected = @connected
    @connected = no
    @connecting = no
    if @was_connected
      if @should_reconnect and !@reconnecting then @reconnect()

_.extend(Websock.prototype, Backbone.Events)
Tp.Websock = Websock
