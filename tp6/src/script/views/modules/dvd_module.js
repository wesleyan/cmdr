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
  var DVDModule;

  DVDModule = Tp.Module.extend({
    name: "dvd",
    buttons: ['play', 'back', 'pause', 'forward', 'stop', 'eject', 'previous', 'next', 'menu', 'title'],
    regions: [
      {
        action: 'enter',
        shape: "circle",
        center: [77, 77],
        radius: 23
      }, {
        action: "left",
        coords: [[77, 77], [23, 23], [0, 77], [23, 131]]
      }, {
        action: "right",
        coords: [[77, 77], [131, 23], [170, 75], [131, 131]]
      }, {
        action: "up",
        coords: [[77, 77], [131, 23], [77, 0], [23, 23]]
      }, {
        action: "down",
        coords: [[77, 77], [131, 131], [77, 170], [23, 131]]
      }
    ],
    render: function() {
      return $.tmpl(this.template_name, {
        buttons: this.buttons
      });
    },
    module_loaded: function() {
      var _this = this;
      $('.five-way').mousedown(function(e) {
        var region, x, y, _i, _len, _ref, _results;
        x = e.originalEvent.offsetX;
        y = e.originalEvent.offsetY;
        _ref = _this.regions;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          region = _ref[_i];
          if (_this.point_in_polygon(region, [x, y])) {
            $('.five-way').attr('class', 'five-way ' + region.action);
            break;
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      });
      $('.five-way').click(function(e) {
        var action;
        action = $('.five-way').attr('class').split(' ')[1];
        $('.five-way').attr('class', 'five-way');
        return _this.do_action(action);
      });
      return $('.dvd-button').click(function(e) {
        return _this.do_action(e.target.title);
      });
    },
    do_action: function(action) {
      var _ref;
      return (_ref = Tp.devices.ir_emitter) != null ? _ref.command(action) : void 0;
    },
    point_in_polygon: function (poly, point){
    var x = point[0];
    var y = point[1];
    if(poly.shape == "circle")
    {
      return Math.pow(x-poly.center[0],2) + Math.pow(y - poly.center[1],2) < Math.pow(poly.radius,2);
    }
    else
    {
      var c, i, l, j;
      poly = poly.coords;
        for(c = false, i = -1, l = poly.length, j = l - 1; ++i < l; j = i)
      {
        var test1 = (poly[i][1] <= y && y < poly[j][1]) || (poly[j][1] <= y && y < poly[i][1]);
        var test2 = x < (poly[j][0] - poly[i][0]) * (y - poly[i][1]) / (poly[j][1] - poly[i][1]) + poly[i][0];
            if(test1 && test2)c = !c;
      }
        return c;
    }
  }
  });

  Tp.modules.dvd = new DVDModule();

}).call(this);
