slinky_require('../../lib/module.coffee')

VCRModule = Tp.Module.extend
  name: "vcr"

  buttons: ['play', 'back', 'pause', 'forward', 'stop']

  render: () ->
    ($.tmpl @template_name, {buttons: @buttons})

  module_loaded: ->
    $('.dvd-button').click (e) =>
      @do_action e.target.title

  do_action: (action) ->
    Tp.devices.ir_emitter?.command action

Tp.modules.vcr = new VCRModule()
