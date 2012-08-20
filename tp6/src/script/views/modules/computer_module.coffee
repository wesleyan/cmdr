slinky_require('../../lib/module.coffee')

ComputerModule = Tp.Module.extend
  initialize: () ->
    Tp.Module.prototype.initialize.call(this);

  name: "computer"

Tp.modules.computer = new ComputerModule()
