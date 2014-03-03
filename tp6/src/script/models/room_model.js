(function() {
  var Room, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Room = (function(_super) {
    __extends(Room, _super);

    function Room() {
      _ref = Room.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    return Room;

  })(Backbone.Model);

  Tp.Room = Room;

}).call(this);
