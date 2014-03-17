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
  Tp.OutputPaneView = Backbone.View.extend({
    initialize: function() {
      var _this = this;
      $.get('../tp6/script/templates/output_module.html', function(template) {
        $.template("output-pane-template", template);
        return _this.render();
      });
      _.bindAll(this, 'projectorChanged');
      Tp.server.bind("loaded", this.projectorChanged);
      Tp.server.bind("loaded", this.videoMuteChanged);
      Tp.devices.projector.bind("change:state", this.projectorChanged);
      Tp.devices.projector.bind("change:video_mute", this.videoMuteChanged);
      Tp.devices.volume.bind("change:mute", this.audioMuteChanged);
      Tp.devices.volume.bind("change:volume", this.audioLevelChanged);
      Tp.sources.bind("change", this.sourceChanged);
      Tp.room.bind("change:source", this.sourceChanged);
      this.bind("autoOffCancel", this.autoOffCancel);
      Tp.room.offTimer = null;
      return Tp.room.warningTimer = null;
    },
    render: function() {
      ($.tmpl("output-pane-template", {
        output_icon: "fa fa-video-camera",
        name: "projector"
      })).appendTo("#o-1");
      console.log("Setting up handlers");

      //NEW INTERFACE
      $('.pwr-btn > label').click(this.powerButtonClicked);
      $('.vm-btn > label').click(this.blankButtonClicked);
      $('#vol-mute').click(this.muteButtonClicked);
      $('#vol-s-1').children().click({volume: 0.2}, this.volumeClicked);
      $('#vol-s-2').children().click({volume: 0.4}, this.volumeClicked);
      $('#vol-s-3').children().click({volume: 0.6}, this.volumeClicked);
      $('#vol-s-4').children().click({volume: 0.8}, this.volumeClicked);
      $('#vol-s-5').children().click({volume: 1.0}, this.volumeClicked);
    

      return $('#vol-knob');
    },
    projectorChanged: function() {
      var state, text;
      state = Tp.devices.projector.get('state');
      this.autoOff(state);
      
      //NEW INTERFACE
      console.log('projector state: ' + state);
      if (state === 'on') {
        $('.vm-btn > label').removeClass('vm-on');
        $('.pwr-btn > label').removeClass('warming').addClass('pwr-on');
      }
      else if (state === 'muted') {
        $('.vm-btn > label').addClass('vm-on');
      }
      else if (state === 'warming') {
        $('.vm-btn > label').removeClass('vm-on');
        $('.pwr-btn > label').removeClass('pwr-on').addClass('warming');
      }
      else {
        $('.vm-btn > label').removeClass('vm-on');
        $('.pwr-btn > label').removeClass('pwr-on warming');
      }

      return $('.screen-image-overlay').css('opacity', text === "off" ? 0 : 0.4);
    },
    autoOff: function(state) {
      var shutOff, warning;
      if (state === "on") {
        shutOff = function() {
          return Tp.devices.projector.state_set('power', false);
        };
        warning = function() {
          $('#auto-off').show();
          return Tp.room.offTimer = setTimeout(shutOff, 60000);
        };
        return Tp.room.warningTimer = setTimeout(warning, 10740000);
      } else if (state === "off") {
        if (Tp.room.warningTimer) {
          clearTimeout(Tp.room.warningTimer);
        }
        if (Tp.room.offTimer) {
          clearTimeout(Tp.room.offTimer);
        }
        return $('#auto-off').hide();
      }
    },
    autoOffCancel: function() {
      clearTimeout(Tp.room.warningTimer);
      clearTimeout(Tp.room.offTimer);
      $('#auto-off').hide();
      return Tp.OutputPane.autoOff("on");
    },
    sourceChanged: function() {
      var state;
      state = Tp.room.get('source');
      console.log("../images/sources/" + state.get('icon'));
      $('.source-image').attr('src', "../images/sources/" + state.get('icon'));
      return $('.source-image').load(function() {
        var H, W, h, sH, sW, w, y, _ref;
        W = this.naturalWidth;
        H = this.naturalHeight;
        console.log("asdf %d, %d", W, H);
        sW = 80;
        sH = 80;
        _ref = W > H ? [sW, sW * (H / W)] : [sH * (H / W), sH], w = _ref[0], h = _ref[1];
        y = (sH - h) / 2 + 80;
        return $(this).height(h).width(w).css('left', "50%").css("margin-left", -w / 2).css('top', y);
      });
    },
    videoMuteChanged: function() {
      var mute, text;
      mute = Tp.devices.projector.get('video_mute');

      //NEW INTERFACE
      if (mute) {
        $('.vm-btn > label').addClass('vm-on');
        text = "show video";
      }
      else {
        $('.vm-btn > label').removeClass('vm-on');
        text = "mute video";
      }

      return text;
    },
    audioMuteChanged: function() {
      var mute, text;
      mute = Tp.devices.volume.get('mute');

      //NEW INTERFACE
      if (mute) {
        $('#vol-mute').addClass('vol-muted-m');
        $('#vol-switches > label').each(function() {
          $(this).children('div').children('div').addClass('vol-muted');
          if ($(this).children('div').children('div').hasClass('vol-checked')) {
            $(this).children('div').children('div').addClass('vol-checked-muted');
          }
        });
        $('input[name="switch"]').attr('disabled',true);
        text = "unmute";
      }
      else {
        $('#vol-mute').removeClass('vol-muted-m');
        $('#vol-switches > label').each(function() {
          $(this).children('div').children('div').removeClass('vol-muted');
          if ($(this).children('div').children('div').hasClass('vol-checked')) {
            $(this).children('div').children('div').removeClass('vol-checked-muted');
          }
        });
        $('input[name="switch"]').attr('disabled',false);
        text = "mute";
      }

      return text;
    },
    audioLevelChanged: function() {
      var level;
      level = Tp.devices.volume.get('volume');

      //NEW INTERFACE
      if (level > 0 && level <= 0.2) {
        $('#vol-s-1').children().click();
      }
      else if (level > 0 && level <= 0.4) {
        $('#vol-s-2').children().click();
      }
      else if (level > 0 && level <= 0.6) {
        $('#vol-s-3').children().click();
      }
      else if (level > 0 && level <= 0.8) {
        $('#vol-s-4').children().click();
      }
      else if (level > 0 && level <= 1) {
        $('#vol-s-5').children().click();
      }
      return level;
    },
    powerButtonClicked: function() {
      var state;
      var label = $('.pwr-btn > label');
      if (label.hasClass('pwr-on')) {
        label.removeClass('pwr-on warming');
      }
      else if (label.hasClass('warming')) { 
      }
      else { 
        label.addClass('warming');
      }
      state = Tp.devices.projector.get('state');
      return Tp.devices.projector.state_set('power', state === "off");
    },
    blankButtonClicked: function() {
      var mute;
      mute = Tp.devices.projector.get('video_mute');
      return Tp.devices.projector.state_set('video_mute', !mute);
    },
    muteButtonClicked: function() {
      var mute;
      mute = Tp.devices.volume.get('mute');
      return Tp.devices.volume.state_set('mute', !mute);
    },
    volumeClicked: function(eventData) {
      var volume = eventData.data.volume;
      return Tp.devices.volume.state_set('volume', volume);
    },
    autoOffClicked: function() {
      return Tp.OutputPane.trigger("autoOffCancel");
    },
    checkState: function() {
      console.log('checking state');
    }
  });

}).call(this);
