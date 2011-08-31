(function() {
  var ButtonView;
  var __extends = function(child, parent) {
    var ctor = function(){};
    ctor.prototype = parent.prototype;
    child.prototype = new ctor();
    child.prototype.constructor = child;
    if (typeof parent.extended === "function") parent.extended(child);
    child.__super__ = parent.prototype;
  };
  ButtonView = function() {
    return Backbone.View.apply(this, arguments);
  };
  __extends(ButtonView, Backbone.View);
  ButtonView.prototype.tagName = 'div';
  ButtonView.prototype.disabled = false;
  ButtonView.prototype.label = "";
  ButtonView.prototype.action = function() {};
  ButtonView.prototype.events = {
    "click": "doAction"
  };
  ButtonView.prototype.initialize = function() {
    return $(this.el).append($(this.make('div')).addClass('control-button').append($(this.make('div').addClass('label'))));
  };
  ButtonView.prototype.render = function() {
    if (this.disabled) {
      if (!($(".control-button").hasClass("disabled"))) {
        $('.control-button').addClass("disabled");
      }
    }
    return $('label').html(this.label);
  };
  ButtonView.prototype.doAction = function() {
    return !(disabled) ? this.action() : null;
  };
}).call(this);
