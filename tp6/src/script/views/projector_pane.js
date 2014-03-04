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
  Tp.ProjectorPaneView = Backbone.View.extend({
    initialize: function() {
      var _this = this;
      $.get('../src/script/templates/projector_module.html', function(template) {
        $.template("projector-pane-template", template);
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
      ($.tmpl("projector-pane-template", {
        status_image: "off.png",
        source_image: "x.png",
        power_button_label: "loading...",
        blank_button_label: "loading...",
        mute_button_label: "loading..."
      })).appendTo("#projector-pane");
      console.log("Setting up handlers");
      $('.power-button').click(this.powerButtonClicked);
      $('.blank-button').click(this.blankButtonClicked);
      $('.mute-button').click(this.muteButtonClicked);
      $('#auto-off .cancel-button').click(this.autoOffClicked);
      $('.volume-slider').slider();
      $('.volume-slider').on("slide", this.volumeSliderChanged);
      return $('.volume-slider').slider("option", "disabled", true);
    },
    projectorChanged: function() {
      var state, text;
      state = Tp.devices.projector.get('state');
      text = ["on", "muted", "warming"].indexOf(state) !== -1 ? "off" : "on";
      this.autoOff(state);
      $('.power-button .label').html("turn " + text);
      $('.status-image').attr('src', '../images/projector/' + state + '.png');
      $('.source-image').css('visibility', text === "off" ? "visible" : "hidden");
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
      return Tp.projectorPane.autoOff("on");
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
      text = mute ? "show video" : "mute video";
      return $('.blank-button .label').html(text);
    },
    audioMuteChanged: function() {
      var mute, text;
      mute = Tp.devices.volume.get('mute');
      text = mute ? "unmute" : "mute";
      return $('.mute-button .label').html(text);
    },
    audioLevelChanged: function() {
      var level;
      level = Tp.devices.volume.get('volume');
      if ($('.volume-slider').slider("option", "disabled")) {
        $('.volume-slider').slider("option", "disabled", false);
        if (level >= 0 && level <= 1) {
          $('.volume-slider').slider("value", level * 100);
          $(".volume-gauge").css("right", (100 - (level * 100)) + "%");
        }
      }
      if (level === 1) {
        return $(".volume-now-gauge").css("right", "7%");
      } else {
        return $(".volume-now-gauge").css("right", (100 - (level * 100)) + "%");
      }
    },
    powerButtonClicked: function() {
      var state;
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
    volumeSliderChanged: function() {
      var sliderVal, volume;
      volume = Tp.devices.volume.get('volume');
      sliderVal = Math.round($(".volume-slider").slider("option", "value") / 10) / 10;
      $(".volume-gauge").css("right", (100 - $(".volume-slider").slider("option", "value")) + "%");
      return Tp.devices.volume.state_set('volume', sliderVal);
    },
    volumeUpClicked: function() {
      var volume;
      volume = Tp.devices.volume.get('volume');
      return Tp.devices.volume.state_set('volume', volume + 0.1);
    },
    volumeDownClicked: function() {
      var volume;
      volume = Tp.devices.volume.get('volume');
      return Tp.devices.volume.state_set('volume', volume - 0.1);
    },
    autoOffClicked: function() {
      return Tp.projectorPane.trigger("autoOffCancel");
    }
  });

}).call(this);
