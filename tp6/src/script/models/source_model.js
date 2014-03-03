(function() {
  var Source, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Source = (function(_super) {
    __extends(Source, _super);

    function Source() {
      _ref = Source.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Source.prototype.select = function() {
      var msg;
      msg = {
        resource: "source",
        "var": "source",
        value: this.get('name')
      };
      return Tp.server.trigger("state_set", msg);
    };

    Source.prototype.selected = function() {
      return Tp.room.source === this.name;
    };

    return Source;

  })(Backbone.Model);

  Tp.Source = Source;

  Tp.SourceController = Backbone.Collection.extend({
    model: Tp.Source
  });

  Tp.sources = new Tp.SourceController;

}).call(this);
