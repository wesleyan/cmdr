(function() {
  var ProjectorButtonView;
  var __extends = function(child, parent) {
    var ctor = function(){};
    ctor.prototype = parent.prototype;
    child.prototype = new ctor();
    child.prototype.constructor = child;
    if (typeof parent.extended === "function") parent.extended(child);
    child.__super__ = parent.prototype;
  };
  ProjectorButtonView = function() {
    return StatusButtonView.apply(this, arguments);
  };
  __extends(ProjectorButtonView, StatusButtonView);
  ProjectorButtonView.prototype.initialize = function() {
    ProjectorButtonView.__super__.initialize.apply(this, arguments);
    $(this.el).append($(this.make('img')));
    return $('.control-drawer').append(ButtonView["new"]({
      action: function() {
        return $(this.el).toggleDrawer();
      }
    }));
  };
}).call(this);
