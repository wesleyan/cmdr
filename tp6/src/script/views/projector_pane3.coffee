slinky_require('../core.coffee')

Tp.ProjectorPaneView3 = Backbone.View.extend
  initialize: () ->
    $.get 'script/templates/projector_module3.html', (template) =>
      $.template "projector-pane3-template", template
      this.render()

    _.bindAll this, 'projector3Changed'

    Tp.server.bind "loaded", @projector3Changed
    Tp.server.bind "loaded", @videoMute3Changed
    Tp.devices.projector3.bind "change:state", @projector3Changed
    Tp.devices.projector3.bind "change:video_mute", @videoMute3Changed
    Tp.devices.volume.bind "change:mute", @audioMute3Changed
    Tp.devices.volume.bind "change:volume", @audioLevel3Changed
    Tp.sources.bind "change", @source3Changed
    Tp.room.bind "change:source3", @source3Changed

  render: () ->
    ($.tmpl "projector-pane3-template", {
      status3_image: "off.png"
      source3_image: "x.png"
      power_button3_label: "loading..."
      blank_button3_label: "loading..."
      mute_button3_label: "loading..."
      selected3_label: "select"
    }).appendTo "#projector-pane3"

    # $(".projector-module").noisy(
    #   'intensity' : 1,
    #   'size' : 200,
    #   'opacity' : 0.08,
    #   'fallback' : '',
    #   'monochrome' : true
    # )

    # events
    #Tp.start = ["setting up handlers", $('.power-button')]
    console.log("Setting up handlers")
    $('.power-button3').click(@powerButton3Clicked)
    $('.blank-button3').click(@blankButton3Clicked)

    $('.volume-minus3').click(@volumeDown3Clicked)
    $('.volume-plus3').click(@volumeUp3Clicked)
    $('.mute-button3').click(@muteButton3Clicked)

    $('.selected3').click(@selected3Clicked)


  projector3Changed: () ->
    state = Tp.devices.projector3.get('state')
    console.log("Projector3 now " + state)
    text = if (["on", "muted", "warming"].indexOf(state) != -1) then "off" else "on"
    $('.power-button3 .label').html("turn " + text)
    $('.status3-image').attr 'src', 'images/projector/' + state + '.png'
    $('.source3-image').css 'visibility', if text == "off" then "visible" else "hidden"
    $('.screen3-image-overlay').css 'opacity', if text == "off" then 0 else 0.4

  source3Changed: () ->
    state = Tp.room.get('source3')
    console.log("images/sources/" + state.get('icon'))
    $('.source3-image').attr 'src', "images/sources/" + state.get('icon')

    $('.source3-image').load ->
      W = this.naturalWidth
      H = this.naturalHeight
      console.log("asdf %d, %d", W, H)
      sW = 80
      sH = 80

      [w, h] = if W > H then [sW, sW * (H/W)] else [sH * (H/W), sH]

      y = (sH - h) / 2 + 80

      $(this).height(h).width(w).css('left', "50%")
        .css("margin-left", -w/2).css('top', y)


  videoMute3Changed: () ->
    mute = Tp.devices.projector3.get('video_mute')
    text = if mute then "show video" else "mute video"
    $('.blank-button3 .label').html(text)

  audioMute3Changed: () ->
    mute = Tp.devices.volume.get('mute')
    text = if mute then "unmute" else "mute"
    $('.mute-button3 .label').html(text)

  audioLevel3Changed: () ->
    level = Tp.devices.volume.get('level')
    if level >= 1 then $('.volume-plus3.button').disable
    if level <= 0 then $('.volume-minus3.button').disable

  powerButton3Clicked: () ->
    state = Tp.devices.projector3.get 'state'
    Tp.devices.projector3.state_set 'power', state == "off"

  blankButton3Clicked: () ->
    mute = Tp.devices.projector3.get('video_mute')
    Tp.devices.projector3.state_set 'video_mute', !mute

  muteButton3Clicked: () ->
    mute = Tp.devices.volume.get 'mute'
    Tp.devices.volume.state_set 'mute', !mute

  volumeUp3Clicked: () ->
    volume = Tp.devices.volume.get 'volume'
    Tp.devices.volume.state_set 'volume', volume + 0.1

  volumeDown3Clicked: () ->
    volume = Tp.devices.volume.get 'volume'
    Tp.devices.volume.state_set 'volume', volume - 0.1

  selected3Clicked: () ->
    if not Tp.devices.selected_projector[2]
      Tp.devices.selected_projector[2] = true
      $('.selected3').addClass 'selected'
      $('.selected3 .label').html('deselect')
    else
      Tp.devices.selected_projector[2] = false
      $('.selected3').removeClass 'selected'
      $('.selected3 .label').html('select')
