slinky_require('websock.coffee')

class Server
  constructor: () ->
    @websock = new Tp.Websock()
    @websock.bind "message", (msg) => @handle_msg msg
    @websock.bind "disconnected", ->
      $('#lost-connection').show()
    @websock.bind "connected", ->
      $('#lost-connection').hide()
    @websock.bind "connecting", ->
      $('#lost-connection .reconnection-attempt').hide()
      $('#lost-connection .reconnecting').show()
    @websock.bind "reconnect_failed", ->
      $('#lost-connection .reconnection-attempt').show()
      $('#lost-connection .reconnecting').hide()
    @websock.bind "reconnecting", (msg) =>
      [delay, attempts] = msg
      reconnection_time = new Date(Date.now()+delay)
      if @reconnection_msg_timer then clearInterval @reconnection_msg_timer
      @reconnection_msg_timer = setInterval((=>
        seconds = Math.round((reconnection_time - Date.now()) / 1000)
        $('#lost-connection .reconnection-counter').html(seconds + " seconds")), 500)

    this.bind 'state_set', (msg) =>
      msg['type'] = 'state_set'
      this.send_message(msg)

    this.bind 'command', (msg) =>
      msg['type'] = 'command'
      this.send_message(msg)

    @requests = {}

    $(window).load => @websock.connect()

  connected: (msg) ->
    # clear out our collections, in case this is reconnection
    Tp.sources.refresh []
    Tp.actions.refresh []
    # set everything up
    room_hash =
      building: msg.building
      name: msg.room

    Tp.room.set room_hash

    Tp.sources.add _.map msg.sources, (x) ->
      id: x.id,
      name: x.name,
      icon: x.icon

    Tp.actions.add _.map msg.actions, (x) ->
      id: x._id
      name: x.name
      source: Tp.sources.get(x.settings?.source)
      prompt_projector: x.settings?.prompt_projector
      module: x.settings?.module

    # get initial states for devices
    this.state_get "projector", "state"
    this.state_get "projector", "video_mute"
    this.state_get "volume", "volume"
    this.state_get "volume", "mute"
    this.state_get "source", "source"
    this.state_get "computer", "reachable"

    # Prevent dragging of images. Wait a little while for stuff to load
    $('img').mousedown (event) -> event.preventDefault()

  send_message: (msg) ->
    msg['id'] = this.createUUID()
    @websock.send(JSON.stringify(msg))
    msg['id']

  handle_msg: (json) ->
    msg = JSON.parse(json)
    console.log(msg)
    switch msg.type
      when "connection"
        @connected msg
      when "state_changed"
        if msg['resource'] == 'source' then this.source_changed msg
        else @device_changed msg
      when "ack"
        "Got ack"
      else
        if @requests[msg['id']]
          @requests[msg['id']](msg)
          delete @requests[msg['id']]
        else Tp.log "Unhandled WS message: " + event.data

  source_changed: (msg) ->
    name = msg['new'] or msg['result']
    state = Tp.sources.find (s) -> s.get('name') == name
    Tp.room.set({source: state})

  device_changed: (msg) ->
    device = Tp.devices[msg['resource']]
    Tp.log("Device changed")
    Tp.log(device)
    hash = {}
    hash[msg['var']] = msg['new']
    Tp.log(hash)
    device.set(hash)

  state_get: (resource, variable, callback) ->
    id = @send_message {
      type: "state_get"
      resource: resource
      var: variable
    }
    @requests[id] = (msg) =>
      return if msg['result'] == null
      switch resource
        when 'source' then this.source_changed msg
        else
          hash = {}
          Tp.log("Setting %s, %s to %s", resource, variable, msg['result'])
          hash[variable] = msg['result']
          Tp.devices[resource].set hash

  createUUID: () ->
    # http://www.ietf.org/rfc/rfc4122.txt
    s = []
    hexDigits = "0123456789ABCDEF"
    for i in [0..31]
      s[i] = hexDigits.substr(Math.floor(Math.random() * 0x10), 1)

    s[12] = "4" # bits 12-15 of the time_hi_and_version field to 0010
    s[16] = hexDigits.substr((s[16] & 0x3) | 0x8, 1)  # bits 6-7 of the clock_seq_hi_and_reserved to 01

    s.join("");

_.extend(Server.prototype, Backbone.Events)
Tp.Server = Server
