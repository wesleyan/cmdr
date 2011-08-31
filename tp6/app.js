(function() {
  var Device, Tp6;
  var __extends = function(child, parent) {
    var ctor = function(){};
    ctor.prototype = parent.prototype;
    child.prototype = new ctor();
    child.prototype.constructor = child;
    if (typeof parent.extended === "function") parent.extended(child);
    child.__super__ = parent.prototype;
  };
  Device = function() {
    return BackBone.Model.apply(this, arguments);
  };
  __extends(Device, BackBone.Model);
  Tp6.device = Device["new"];
  Tp6 = Object["new"];
}).call(this);
