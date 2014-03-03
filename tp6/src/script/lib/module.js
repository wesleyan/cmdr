(function() {
  Tp.Module = Backbone.View.extend({
    initialize: function() {
      var _this = this;
      this.template_name = "action_template_" + this.name;
      if ($.template(this.template_name) instanceof Function) {
        return this.template_loaded();
      } else {
        return $.get('../src/script/templates/modules/' + this.name + '.html', function(template) {
          $.template(_this.template_name, template);
          return _this.template_loaded();
        });
      }
    },
    template_loaded: function() {},
    module_loaded: function() {}
  });

}).call(this);
