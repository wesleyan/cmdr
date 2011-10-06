slinky_require('../core.coffee')

Tp.ProjectorPaneView = Backbone.View.extend
  initialize: () ->
    $.get 'script/templates/projector_module.html', (template) =>
      $.template "projector-pane-template", template
      this.render()

      # events
      $('.power-button').click(@powerButtonClicked)
      $('.blank-button').click(@blankButtonClicked)

      $('.volume-minus').click(@volumeDownClicked)
      $('.volume-plus').click(@volumeUpClicked)
      $('.mute-button').click(@muteButtonClicked)

    _.bindAll this, 'projectorChanged'

    Tp.server.bind "loaded", @projectorChanged
    Tp.server.bind "loaded", @videoMuteChanged
    Tp.devices.projector.bind "change:state", @projectorChanged
    Tp.devices.projector.bind "change:video_mute", @videoMuteChanged
    Tp.devices.volume.bind "change:mute", @audioMuteChanged
    Tp.devices.volume.bind "change:volume", @audioLevelChanged
    Tp.sources.bind "change", @sourceChanged
    Tp.room.bind "change:source", @sourceChanged

  render: () ->
    ($.tmpl "projector-pane-template", {
      status_image: "off.png"
      source_image: "x.png"
      power_button_label: "loading..."
      blank_button_label: "loading..."
      mute_button_label: "loading..."
    }).appendTo "#projector-pane"

    $(".projector-module").noisy(
      'intensity' : 1,
      'size' : 200,
      'opacity' : 0.08,
      'fallback' : '',
      'monochrome' : true
    )

  projectorChanged: () ->
    state = Tp.devices.projector.get('state')
    console.log("Projector now " + state)
    text = if (["on", "muted", "warming"].indexOf(state) != -1) then "off" else "on"
    $('.power-button .label').html("turn " + text)
    $('.status-image').attr 'src', 'images/projector/' + state + '.png'
    $('.source-image').css 'visibility', if text == "off" then "visible" else "hidden"
    $('.screen-image-overlay').css 'opacity', if text == "off" then 0 else 0.4

  sourceChanged: () ->
    state = Tp.room.get('source')
    console.log("images/sources/" + state.get('icon'))
    $('.source-image').attr 'src', "images/sources/" + state.get('icon')

    $('.source-image').load ->
      W = this.naturalWidth
      H = this.naturalHeight
      console.log("asdf %d, %d", W, H)
      sW = 80
      sH = 80

      [w, h] = if W > H then [sW, sW * (W/H)] else [sH * (H/W), sH]

      y = (sH - h) / 2 + 80

      $(this).height(h).width(w).css('left', "50%")
        .css("margin-left", -w/2).css('top', y)


  videoMuteChanged: () ->
    mute = Tp.devices.projector.get('video_mute')
    text = if mute then "show video" else "mute video"
    $('.blank-button .label').html(text)

  audioMuteChanged: () ->
    mute = Tp.devices.volume.get('mute')
    text = if mute then "unmute" else "mute"
    $('.mute-button .label').html(text)

  audioLevelChanged: () ->
    level = Tp.devices.volume.get('level')
    if level >= 1 then $('.volume-plus.button').disable
    if level <= 0 then $('.volume-minus.button').disable

  powerButtonClicked: () ->
    state = Tp.devices.projector.get 'state'
    Tp.devices.projector.state_set 'power', state == "off"

  blankButtonClicked: () ->
    mute = Tp.devices.projector.get('video_mute')
    Tp.devices.projector.state_set 'video_mute', !mute

  muteButtonClicked: () ->
    mute = Tp.devices.volume.get 'mute'
    Tp.devices.volume.state_set 'mute', !mute

  volumeUpClicked: () ->
    volume = Tp.devices.volume.get 'volume'
    Tp.devices.volume.state_set 'volume', volume + 0.1

  volumeDownClicked: () ->
    volume = Tp.devices.volume.get 'volume'
    Tp.devices.volume.state_set 'volume', volume - 0.1
