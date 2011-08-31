slinky_require('../main.coffee')

class Device extends Backbone.Model
  state_set: (variable, value) ->
    msg =
      var: variable,
      value: value,
      resource: this.get('name')

    Tp.server.trigger("state_set", msg)

  command: (name, args = []) ->
    msg = {
      resource: this.get('name')
      method: name
      args: args
    }
    Tp.server.trigger("command", msg)

Tp.Device = Device
