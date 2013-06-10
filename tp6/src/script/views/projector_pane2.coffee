slinky_require('../core.coffee')

Tp.ProjectorPaneView2 = Backbone.View.extend
  initialize: () ->
    $.get 'script/templates/projector_module2.html', (template) =>
      $.template "projector-pane2-template", template
      this.render()

    _.bindAll this, 'projector2Changed'

    Tp.server.bind "loaded", @projector2Changed
    Tp.server.bind "loaded", @videoMute2Changed
    Tp.devices.projector2.bind "change:state", @projector2Changed
    Tp.devices.projector2.bind "change:video_mute", @videoMute2Changed
    Tp.devices.volume.bind "change:mute", @audioMute2Changed
    Tp.devices.volume.bind "change:volume", @audioLevel2Changed
    Tp.sources.bind "change", @source2Changed
    Tp.room.bind "change:source2", @source2Changed

  render: () ->
    ($.tmpl "projector-pane2-template", {
      status2_image: "off.png"
      source2_image: "x.png"
      power_button2_label: "loading..."
      blank_button2_label: "loading..."
      mute_button2_label: "loading..."
      selected2_label: "select"
    }).appendTo "#projector-pane2"

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
    $('.power-button2').click(@powerButton2Clicked)
    $('.blank-button2').click(@blankButton2Clicked)

    $('.volume-minus2').click(@volumeDown2Clicked)
    $('.volume-plus2').click(@volumeUp2Clicked)
    $('.mute-button2').click(@muteButton2Clicked)

    $('.selected2').click(@selected2Clicked)


  projector2Changed: () ->
    state = Tp.devices.projector2.get('state')
    console.log("Projector2 now " + state)
    text = if (["on", "muted", "warming"].indexOf(state) != -1) then "off" else "on"
    $('.power-button2 .label').html("turn " + text)
    $('.status2-image').attr 'src', 'images/projector/' + state + '.png'
    $('.source2-image').css 'visibility', if text == "off" then "visible" else "hidden"
    $('.screen2-image-overlay').css 'opacity', if text == "off" then 0 else 0.4

  source2Changed: () ->
    state = Tp.room.get('source2')
    console.log("images/sources/" + state.get('icon'))
    $('.source2-image').attr 'src', "images/sources/" + state.get('icon')

    $('.source2-image').load ->
      W = this.naturalWidth
      H = this.naturalHeight
      console.log("asdf %d, %d", W, H)
      sW = 80
      sH = 80

      [w, h] = if W > H then [sW, sW * (H/W)] else [sH * (H/W), sH]

      y = (sH - h) / 2 + 80

      $(this).height(h).width(w).css('left', "50%")
        .css("margin-left", -w/2).css('top', y)


  videoMute2Changed: () ->
    mute = Tp.devices.projector2.get('video_mute')
    text = if mute then "show video" else "mute video"
    $('.blank-button2 .label').html(text)

  audioMute2Changed: () ->
    mute = Tp.devices.volume.get('mute')
    text = if mute then "unmute" else "mute"
    $('.mute-button2 .label').html(text)

  audioLevel2Changed: () ->
    level = Tp.devices.volume.get('level')
    if level >= 1 then $('.volume-plus2.button').disable
    if level <= 0 then $('.volume-minus2.button').disable

  powerButton2Clicked: () ->
    state = Tp.devices.projector2.get 'state'
    Tp.devices.projector2.state_set 'power', state == "off"

  blankButton2Clicked: () ->
    mute = Tp.devices.projector2.get('video_mute')
    Tp.devices.projector2.state_set 'video_mute', !mute

  muteButton2Clicked: () ->
    mute = Tp.devices.volume.get 'mute'
    Tp.devices.volume.state_set 'mute', !mute

  volumeUp2Clicked: () ->
    volume = Tp.devices.volume.get 'volume'
    Tp.devices.volume.state_set 'volume', volume + 0.1

  volumeDown2Clicked: () ->
    volume = Tp.devices.volume.get 'volume'
    Tp.devices.volume.state_set 'volume', volume - 0.1

  selected2Clicked: () ->
    if not Tp.devices.selected_projector[1]
      Tp.devices.selected_projector[1] = true
      $('.selected2').addClass 'selected'
      $('.selected2 .label').html('deselect')
    else
      Tp.devices.selected_projector[1] = false
      $('.selected2').removeClass 'selected'
      $('.selected2 .label').html('select')
