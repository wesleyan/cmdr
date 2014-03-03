(function() {
  var Device, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Device = (function(_super) {
    __extends(Device, _super);

    function Device() {
      _ref = Device.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Device.prototype.state_set = function(variable, value) {
      var msg;
      msg = {
        "var": variable,
        value: value,
        resource: this.get('name')
      };
      return Tp.server.trigger("state_set", msg);
    };

    Device.prototype.command = function(name, args) {
      var msg;
      if (args == null) {
        args = [];
      }
      msg = {
        resource: this.get('name'),
        "var": name,
        method: name,
        args: args
      };
      return Tp.server.trigger("command", msg);
    };

    return Device;

  })(Backbone.Model);

  Tp.Device = Device;

}).call(this);
