slinky_require '../../lib/module.coffee'

ComputerModule = Tp.Module.extend
  initialize: () ->
    Tp.devices.computer?.bind "change:reachable", @reachable_changed
    Tp.Module.prototype.initialize.call(this);

  name: "computer"
  render: () ->
    ($.tmpl @template_name)

  module_loaded: () ->
    @reachable_changed()
    $('.on-button.control-button').click(@on_button_clicked)

  reachable_changed: () ->
    state = Tp.devices.computer?.get('reachable')
    Tp.log("State = " + state)
    if state
      Tp.log "Setting computer on"
      $('.computer-off').css('display', 'none')
      $('.computer-on').css('display', 'block')
    else
      Tp.log "Setting computer off"
      $('.computer-off').css('display', 'block')
      $('.computer-on').css('display', 'none')

  on_button_clicked: () ->
    Tp.log("Starting computer...")
    Tp.devices.computer.command("start")


Tp.modules.computer = new ComputerModule()
