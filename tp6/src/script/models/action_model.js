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
    source: function() {
      var _ref;
      _ref = this.get('source').get('name');
      if (_ref) _ref = _ref.substring(0,6).toLowerCase();
      return _ref;
    },
    css: function(size) {
      var _ref;
      _ref = this.sourceType();
      switch (_ref.toLowerCase()) {
        case 'hdmi':
          return 'icon-hdmi icon-' + size + 'x';
        case 'vga':
          return 'icon-vga icon-' + size + 'x';
        case 'mac':
          return 'icon-apple icon-' + size + 'x';
        case 'pc':
          return 'icon-windows icon-' + size + 'x';
        case 'dvd':
          return 'icon-vynil icon-' + size + 'x';
        case 'bluray':
          return 'icon-vynil icon-' + size + 'x';
        default:
          return 'icon-cmdr icon-' + size + 'x';
      }
    },
    sourceType: function() {
      var _ref, re_hdmi, re_vga, re_mac, re_pc, re_bluray, re_dvd, re_vcr;
      _ref = this.get('source').get('name');
      re_hdmi = /hdmi/i;
      re_vga = /vga/i;
      re_mac = /mac/i;
      re_pc = /pc/i;
      re_bluray = /bluray/i;
      re_dvd = /dvd/i;
      re_vcr = /vcr/i;
      if (re_hdmi.exec(_ref)) return 'hdmi';
      if (re_vga.exec(_ref)) return 'vga';
      if (re_mac.exec(_ref)) return 'mac';
      if (re_pc.exec(_ref)) return 'pc';
      if (re_bluray.exec(_ref)) return 'bluray';
      if (re_dvd.exec(_ref)) return 'dvd';
      if (re_vcr.exec(_ref)) return 'vcr';
      return 'cmdr';
    }
    
  });

  Tp.ActionController = Backbone.Collection.extend({
    model: Tp.Action,
    select: function(id) {
      var action, sel;
      action = this.get(id);
      console.log('Action controller action: ');
      console.log(action);
      if (action) {
        Tp.log("Selecting %s", action);
        sel = action.attributes.name.toLowerCase();
        action.select();
        this.selection = action;
        return this.trigger("change:selection");
      }
    }
  });

  Tp.actions = new Tp.ActionController;

}).call(this);
