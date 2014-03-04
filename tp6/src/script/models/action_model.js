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
