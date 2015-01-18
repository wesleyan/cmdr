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
  Tp.InputListView = Backbone.View.extend({
    initialize: function() {
      var _this = this;
      return $.get('/script/templates/input_list.html', function(template) {
        $.template("input-list-template", template);
        Tp.server.bind("loaded", _this.render);
        Tp.actions.bind("add", _this.render);
        Tp.actions.bind("change", _this.render);
        return Tp.actions.bind("change:selection", _this.selectionChanged);
      });
    },
    render: function() {
      var actionItemClicked, _ref
        _this = this;
      $('.sources-list').html($.tmpl("input-list-template", (_ref = Tp.actions) != null ? _ref.map(function(action) {
          return {
            id: action.get('id'),
            name: action.source(),
            css: action.css(4)
          };
      }) : void 0));

      actionItemClicked = function(event) {
        console.log("Trying to select " + event.currentTarget.id);
        return Tp.actions.select(event.currentTarget.id);
      };
      return window.setTimeout((function() {
        return $('.input-list-item').unbind('click').click(actionItemClicked);
      }), 500);
    },
    selectionChanged: function() {
      var _ref, _sel;
      _ref = Tp.actions.selection;
      _sel = $('#' + (_ref != null ? _ref.id : void 0));
      console.log(_sel);
      console.log('selection changed '+Tp.actions.selection.id);
      $('.input-list-item').removeClass('src-selected');
      _sel.addClass('src-selected');

      return _sel;
    }
  });

}).call(this);
