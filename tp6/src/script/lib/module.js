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
  Tp.Module = Backbone.View.extend({
    initialize: function() {
      var _this = this;
      this.template_name = "action_template_" + this.name;
      if ($.template(this.template_name) instanceof Function) {
        return this.template_loaded();
      } else {
        return $.get('../tp6/script/templates/modules/' + this.name + '.html', function(template) {
          $.template(_this.template_name, template);
          return _this.template_loaded();
        });
      }
    },
    template_loaded: function() {},
    module_loaded: function() {}
  });

}).call(this);
