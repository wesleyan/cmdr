(function() {
  Tp.ContextView = Backbone.View.extend({
    initialize: function() {
      return Tp.actions.bind("change:selection", this.actionChanged);
    },
    actionChanged: function() {
      var action, module;
      action = Tp.actions.selection;
      module = Tp.modules[action != null ? typeof action.get === "function" ? action.get('module') : void 0 : void 0];
      Tp.log(module);
      $(".context-area").html((module != null ? typeof module.render === "function" ? module.render() : void 0 : void 0) || "");
      return module != null ? typeof module.module_loaded === "function" ? module.module_loaded() : void 0 : void 0;
    }
  });

}).call(this);
