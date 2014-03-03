(function() {
  var VCRModule;

  VCRModule = Tp.Module.extend({
    name: "vcr",
    buttons: ['play', 'back', 'pause', 'forward', 'stop'],
    render: function() {
      return $.tmpl(this.template_name, {
        buttons: this.buttons
      });
    },
    module_loaded: function() {
      var _this = this;
      return $('.dvd-button').click(function(e) {
        return _this.do_action(e.target.title);
      });
    },
    do_action: function(action) {
      var _ref;
      return (_ref = Tp.devices.ir_emitter) != null ? _ref.command(action) : void 0;
    }
  });

  Tp.modules.vcr = new VCRModule();

}).call(this);
