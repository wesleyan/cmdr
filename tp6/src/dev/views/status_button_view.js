(function() {
  var StatusButtonView;
  var __extends = function(child, parent) {
    var ctor = function(){};
    ctor.prototype = parent.prototype;
    child.prototype = new ctor();
    child.prototype.constructor = child;
    if (typeof parent.extended === "function") parent.extended(child);
    child.__super__ = parent.prototype;
  };
  StatusButtonView = function() {
    return Backbone.View.apply(this, arguments);
  };
  __extends(StatusButtonView, Backbone.View);
  StatusButtonView.prototype.tagName = 'div';
  StatusButtonView.prototype.className = "status-button";
  StatusButtonView.prototype.drawer_down = false;
  StatusButtonView.prototype.events = {
    "click .button": "toggleDrawer"
  };
  StatusButtonView.prototype.initialize = function() {
    $(this.el).append($(this.make('div')).addClass('button'));
    return $(this.el).append($(this.make('div')).addClass('control-drawer'));
  };
  StatusButtonView.prototype.toggleDrawer = function() {
    return $(".control-drawer").slideToggle(0.25);
  };
}).call(this);
