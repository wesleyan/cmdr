(function() {
  Tp.Action = Backbone.Model.extend({
    select: function() {
      var _ref;
      return (_ref = this.get('source')) != null ? _ref.select() : void 0;
    },
    icon: function() {
      var _ref;
      return this.get('icon') || ((_ref = this.get('source')) != null ? _ref.get('icon') : void 0);
    }
  });

  Tp.ActionController = Backbone.Collection.extend({
    model: Tp.Action,
    select: function(id) {
      var action;
      action = this.get(id);
      if (action) {
        Tp.log("Selecting %s", action);
        action.select();
        this.selection = action;
        return this.trigger("change:selection");
      }
    }
  });

  Tp.actions = new Tp.ActionController;

}).call(this);
