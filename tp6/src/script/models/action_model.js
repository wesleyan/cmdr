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
    },
    css: function(size) {
      var _ref;
      _ref = this.get('name');
      switch (_ref.toLowerCase()) {
        case 'hdmi':
          return 'cf icon-hdmi cf-' + size + 'x';
        case 'vga':
          return 'cf icon-vga cf-' + size + 'x';
        case 'mac':
          return 'fa fa-apple fa-' + size + 'x';
        case 'pc':
          return 'fa fa-windows fa-' + size + 'x';
        case 'dvd':
          return 'cf icon-dvd cf-' + size + 'x';
        case 'bluray':
          return 'cf icon-dvd cf-' + size + 'x';
        default:
          return 'cf icon-cmdr cf-' + size + 'x';
      }
    }
  });

  Tp.ActionController = Backbone.Collection.extend({
    model: Tp.Action,
    select: function(id) {
      var action, cube_face, sel;
      var face_map = {'mac':'c-1','pc':'c-2','hdmi':'c-3','vga':'c-4','dvd':'c-5'};
      action = this.get(id);
      console.log('Action controller action: ');
      console.log(action);
      if (action) {
        Tp.log("Selecting %s", action);
        sel = action.attributes.name.toLowerCase();
        cube_face = face_map[sel] ? face_map[sel] : 'c-6'; //hackey solution
        $('.cube').removeClass('c-1 c-2 c-3 c-4 c-5 c-6').addClass(cube_face);
        action.select();
        this.selection = action;
        return this.trigger("change:selection");
      }
    }
  });

  Tp.actions = new Tp.ActionController;

}).call(this);
