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
