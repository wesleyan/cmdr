(function() {
  var __slice = [].slice;

  window.Tp = {
    debugging: true,
    log: function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (this.debugging) {
        return console.log.apply(console, args);
      }
    },
    modules: {}
  };

}).call(this);
