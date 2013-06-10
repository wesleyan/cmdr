slinky_require('../core.coffee')

Tp.ProjectorPaneView1 = Backbone.View.extend
  initialize: () ->
    $.get 'script/templates/projector_module1.html', (template) =>
      $.template "projector-pane1-template", template
      this.render()

    _.bindAll this, 'projector1Changed'

    Tp.server.bind "loaded", @projector1Changed
    Tp.server.bind "loaded", @videoMute1Changed
    Tp.devices.projector1.bind "change:state", @projector1Changed
    Tp.devices.projector1.bind "change:video_mute", @videoMute1Changed
    Tp.devices.volume.bind "change:mute", @audioMute1Changed
    Tp.devices.volume.bind "change:volume", @audioLevel1Changed
    Tp.sources.bind "change", @source1Changed
    Tp.room.bind "change:source1", @source1Changed

  render: () ->
    ($.tmpl "projector-pane1-template", {
      status1_image: "off.png"
      source1_image: "x.png"
      power_button1_label: "loading..."
      blank_button1_label: "loading..."
      mute_button1_label: "loading..."
      selected1_label: "select"
    }).appendTo "#projector-pane1"

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
    $('.power-button1').click(@powerButton1Clicked)
    $('.blank-button1').click(@blankButton1Clicked)

    $('.volume-minus1').click(@volumeDown1Clicked)
    $('.volume-plus1').click(@volumeUp1Clicked)
    $('.mute-button1').click(@muteButton1Clicked)

    $('.selected1').click(@selected1Clicked)


  projector1Changed: () ->
    state = Tp.devices.projector1.get('state')
    console.log("Projector1 now " + state)
    text = if (["on", "muted", "warming"].indexOf(state) != -1) then "off" else "on"
    $('.power-button1 .label').html("turn " + text)
    $('.status1-image').attr 'src', 'images/projector/' + state + '.png'
    $('.source1-image').css 'visibility', if text == "off" then "visible" else "hidden"
    $('.screen1-image-overlay').css 'opacity', if text == "off" then 0 else 0.4

  source1Changed: () ->
    state = Tp.room.get('source1')
    console.log("images/sources/" + state.get('icon'))
    $('.source1-image').attr 'src', "images/sources/" + state.get('icon')

    $('.source1-image').load ->
      W = this.naturalWidth
      H = this.naturalHeight
      console.log("asdf %d, %d", W, H)
      sW = 80
      sH = 80

      [w, h] = if W > H then [sW, sW * (H/W)] else [sH * (H/W), sH]

      y = (sH - h) / 2 + 80

      $(this).height(h).width(w).css('left', "50%")
        .css("margin-left", -w/2).css('top', y)


  videoMute1Changed: () ->
    mute = Tp.devices.projector1.get('video_mute')
    text = if mute then "show video" else "mute video"
    $('.blank-button1 .label').html(text)

  audioMute1Changed: () ->
    mute = Tp.devices.volume.get('mute')
    text = if mute then "unmute" else "mute"
    $('.mute-button1 .label').html(text)

  audioLevel1Changed: () ->
    level = Tp.devices.volume.get('level')
    if level >= 1 then $('.volume-plus1.button').disable
    if level <= 0 then $('.volume-minus1.button').disable

  powerButton1Clicked: () ->
    state = Tp.devices.projector1.get 'state'
    Tp.devices.projector1.state_set 'power', state == "off"

  blankButton1Clicked: () ->
    mute = Tp.devices.projector1.get('video_mute')
    Tp.devices.projector1.state_set 'video_mute', !mute

  muteButton1Clicked: () ->
    mute = Tp.devices.volume.get 'mute'
    Tp.devices.volume.state_set 'mute', !mute

  volumeUp1Clicked: () ->
    volume = Tp.devices.volume.get 'volume'
    Tp.devices.volume.state_set 'volume', volume + 0.1

  volumeDown1Clicked: () ->
    volume = Tp.devices.volume.get 'volume'
    Tp.devices.volume.state_set 'volume', volume - 0.1

  selected1Clicked: () ->
    if not Tp.devices.selected_projector[0]
      Tp.devices.selected_projector[0] = true
      $('.selected1').addClass 'selected'
      $('.selected1 .label').html("deselect")
    else
      Tp.devices.selected_projector[0] = false
      $('.selected1').removeClass 'selected'
      $('.selected1 .label').html('select')
