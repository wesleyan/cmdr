(function() {
  var Device;
  var __extends = function(child, parent) {
    var ctor = function(){};
    ctor.prototype = parent.prototype;
    child.prototype = new ctor();
    child.prototype.constructor = child;
    if (typeof parent.extended === "function") parent.extended(child);
    child.__super__ = parent.prototype;
  };
  Device = function() {
    return Backbone.Model.apply(this, arguments);
  };
  __extends(Device, Backbone.Model);
  Tp6.device = Device["new"];
}).call(this);
