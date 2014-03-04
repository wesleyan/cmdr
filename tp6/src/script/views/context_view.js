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
