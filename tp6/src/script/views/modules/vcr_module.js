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
