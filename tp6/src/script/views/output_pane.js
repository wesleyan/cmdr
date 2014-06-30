/**
 * Copyright (C) 2014 Wesleyan University
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); * you may not use this file except in compliance with the License.
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
      //this.sourcesList = new Tp.InputListView();
      return Tp.room.warningTimer = null;
    },
    render: function() {
      ($.tmpl("output-pane-template", {
        output_icon: "icon-facetime-video icon-2x",
        name: "Projector",
        power_button_label: "Off",
        blank_button_label: "Video Mute"
      })).appendTo("#outputs");
      $('.out-list > nav').append('<li class="nav-active"><span>Projector</span><i class="icon-arrow-right3 icon-1x"></i></li>');
      console.log("Setting up handlers");
      
      //NEW INTERFACE
      //this.sourcesList.render();
      $('.pwr-btn').click(this.powerButtonClicked);
      $(document).on('click', '.vol-lvl > div', this.volumeClicked);
      $(document).on('click', '.vol-mute', this.audioMuteClicked);
      $(document).on('click', '.blank-btn', this.blankButtonClicked);

      this.projectorChanged();
      this.sourceChanged();

      return;
    },
    projectorChanged: function() {
      var state, text, btnClass;
      state = Tp.devices.projector.get('state');
      this.autoOff(state);
      
      toggleSpinner(false);
      if (state === 'on') {
        text = 'On';
        $('.pwr-btn').removeClass('pwr-warming pwr-cooling').addClass('pwr-on').children('i').removeClass('blink');
        $('.proj-info').children('.alert-txt').html('On');
      }
      else if (state === 'muted') {
        text = 'On';
        $('.proj-info').children('.alert-txt').html('Mute');
      }
      else if (state === 'warming') {
        text = 'Warming';
        $('.pwr-btn').removeClass('pwr-on pwr-cooling').addClass('pwr-warming').children('i').addClass('blink');
        $('.proj-info').children('.alert-txt').html('Warming');
      }
      else if (state === 'cooling') {
        text = 'Cooling';
        btnClass = 'info';
        $('.pwr-btn').removeClass('pwr-on pwr-warming').addClass('pwr-cooling').children('i').addClass('blink');
        $('.proj-info').children('.alert-txt').html('Cooling');
      }
      else if (state === 'off') {
        text = 'Off';
        btnClass = 'danger';
        $('.pwr-btn').removeClass('pwr-on pwr-warming pwr-cooling').children('i').removeClass('blink');
        $('.proj-info').children('.alert-txt').html('Off');
      }
      
      return $('.screen-image-overlay').css('opacity', text === "Off" ? 0 : 0.4);
    },
    changeClass: function(el, pre, newClass) {
      $(el).removeClass(pre+'info '+pre+'warning '+pre+'success '+pre+'danger '+pre+'default ').addClass(pre+newClass);
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
      toggleSpinner(false);
      state = Tp.room.get('source');
      console.log(state);
      if (state) $('#'+state.id).trigger('click');
      return ;
    },
    videoMuteChanged: function() {
      var mute, text;
      toggleSpinner(false);
      mute = Tp.devices.projector.get('video_mute');

      if (mute) {
        $('.blank-btn').addClass('blank-mute');
        text = "Unmute Video";
      }
      else {
        $('.blank-btn').removeClass('blank-mute');
        text = "Mute Video";
      }
      return $('.blank-btn > span').html(text);
    },
    audioMuteChanged: function() {
      var mute, text;
      toggleSpinner(false);
      mute = Tp.devices.volume.get('mute');
      if (mute) {
        $('.vol').not('.vol-mute').addClass('vol-muted');
        $('.vol-mute').addClass('red');
      }
      else {
        $('.vol').removeClass('vol-muted');
        $('.vol-mute').removeClass('red');
      }

      return text;
    },
    audioLevelChanged: function() {
      var level;
      toggleSpinner(false);
      level = Tp.devices.volume.get('volume');
      console.log("audio level changed " + level) ;

      level < 0.1 ? $('#vol-1').removeClass('vol-on') : $('#vol-1').addClass('vol-on');
      level < 0.2 ? $('#vol-2').removeClass('vol-on') : $('#vol-2').addClass('vol-on');
      level < 0.3 ? $('#vol-3').removeClass('vol-on') : $('#vol-3').addClass('vol-on');
      level < 0.4 ? $('#vol-4').removeClass('vol-on') : $('#vol-4').addClass('vol-on');
      level < 0.5 ? $('#vol-5').removeClass('vol-on') : $('#vol-5').addClass('vol-on');
      level < 0.6 ? $('#vol-6').removeClass('vol-on') : $('#vol-6').addClass('vol-on');
      level < 0.7 ? $('#vol-7').removeClass('vol-on') : $('#vol-7').addClass('vol-on');
      level < 0.8 ? $('#vol-8').removeClass('vol-on') : $('#vol-8').addClass('vol-on');
      level < 0.9 ? $('#vol-9').removeClass('vol-on') : $('#vol-9').addClass('vol-on');

      return level;
    },
    powerButtonClicked: function() {
      var state;
      toggleSpinner(true);
      state = Tp.devices.projector.get('state');
      return Tp.devices.projector.state_set('power', state === "off");
    },
    blankButtonClicked: function() {
      var mute;
      toggleSpinner(true);
      mute = Tp.devices.projector.get('video_mute');
      return Tp.devices.projector.state_set('video_mute', !mute);
    },
    audioMuteClicked: function() {
      var mute;
      toggleSpinner(true);
      mute = Tp.devices.volume.get('mute');
      return Tp.devices.volume.state_set('mute', !mute);
    },
    volumeClicked: function(eventData) {
      var volume = eventData.target.id; //we search the id for the first digit
      var d = volume[volume.search(/\d/)];  //and set the voluem to that divided by 10
      var vol = d ? d/10 : 0 ; 
      toggleSpinner(true);
      console.log("volume " + volume[d] + " " + volume);
      return Tp.devices.volume.state_set('volume', vol);
    },
    autoOffClicked: function() {
      return Tp.OutputPane.trigger("autoOffCancel");
    },
    checkState: function() {
      console.log('checking state');
    },
  });

}).call(this);
