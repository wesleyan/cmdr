/**
 * Copyright (C) 2014 Wesleyan University
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

(function() {
  var Device, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Device = (function(_super) {
    __extends(Device, _super);

    function Device() {
      _ref = Device.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Device.prototype.state_set = function(variable, value) {
      var msg;
      msg = {
        "var": variable,
        value: value,
        resource: this.get('name')
      };
      return Tp.server.trigger("state_set", msg);
    };

    Device.prototype.command = function(name, args) {
      var msg;
      if (args == null) {
        args = [];
      }
      msg = {
        resource: this.get('name'),
        "var": name,
        method: name,
        args: args
      };
      return Tp.server.trigger("command", msg);
    };

    return Device;

  })(Backbone.Model);

  Tp.Device = Device;

}).call(this);
