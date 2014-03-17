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
      $.get('../tp6/script/templates/projector_module.html', function(template) {
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
      Tp.room.offTimer = null;
      Tp.room.warningTimer = null;
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
      $('.volume-slider').slider();
      $('.volume-slider').on("slide", this.volumeSliderChanged);

      //NEW INTERFACE
      $('.pwr-btn > label').click(this.powerButtonClicked);
      $('.vm-btn > label').click(this.blankButtonClicked);
      $('#vol-mute').click(this.muteButtonClicked);
      $('#vol-s-1').children().click({volume: 0.2}, this.volumeClicked);
      $('#vol-s-2').children().click({volume: 0.4}, this.volumeClicked);
      $('#vol-s-3').children().click({volume: 0.6}, this.volumeClicked);
      $('#vol-s-4').children().click({volume: 0.8}, this.volumeClicked);
      $('#vol-s-5').children().click({volume: 1.0}, this.volumeClicked);
    

      return $('.volume-slider').slider("option", "disabled", true);
    },
    projectorChanged: function() {
      var state, text;
      state = Tp.devices.projector.get('state');
      text = ["on", "muted", "warming"].indexOf(state) !== -1 ? "off" : "on";
      $('.power-button .label').html("turn " + text);
      $('.status-image').attr('src', '../images/projector/' + state + '.png');
      $('.source-image').css('visibility', text === "off" ? "visible" : "hidden");
      
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

      //NEW INTERFACE
      if (mute) {
        $('.vm-btn > label').addClass('vm-on');
      }
      else {
        $('.vm-btn > label').removeClass('vm-on');
      }

      return $('.blank-button .label').html(text);
    },
    audioMuteChanged: function() {
      var mute, text;
      mute = Tp.devices.volume.get('mute');
      text = mute ? "unmute" : "mute";

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
      }

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
    volumeClicked: function(eventData) {
      var volume = eventData.data.volume;
      return Tp.devices.volume.state_set('volume', volume);
    },
  });

}).call(this);
