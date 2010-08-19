// ==========================================================================
// Project:   Tp5.VolumeButtonView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 sprintf */

/** @class

  (Document Your View Here)

  @extends Tp5.StatusButtonView
*/

sc_require('views/status_button');
sc_require('lib/sprintf');

Tp5.VolumeButtonView = Tp5.StatusButtonView.extend(
/** @scope Tp5.VolumeButtonView.prototype */ {

	childViews: "button controlDrawer imageView volumeLabel muteOverlay".w(),

	imageView: SC.ImageView.design({		
		layout: {left: 5, centerY: 0, width: 52, height: 52},
		value: sc_static("speaker.png")
	}),
	
	muteOverlay: SC.ImageView.design(SC.Animatable, {
		layout: {width: 74, height: 74, centerX: 0, centerY: 0},
		value: sc_static("mute_overlay.png"),
		transitions: {
			opacity: 0.5
		},
		
		muteChanged: function(){
			if(Tp5.volumeController.mute)this.adjust("opacity", 1);
			else this.adjust("opacity", 0);
		}.observes("Tp5.volumeController.mute")
	}),
	
	volumeLabel: SC.LabelView.design({
		layout: {right: 10, centerY: 0, width: 60, height: 28},
		valueBinding: SC.Binding.transform(function(value, binding){
			return sprintf("%.0f%%", Tp5.volumeController.get('lastVolumeSet')*100);
		}).from("Tp5.volumeController.lastVolumeSet"),
		textAlign: "right"
	}),
	
	controlDrawer: SC.View.design(SC.Animatable, {
		classNames: ['control-drawer', 'volume-control'],
		
		extendedHeight: 420,
			
		layout: {centerX:0, width: 70, top:2, bottom: 0},
		
		transitions: {
			height: { duration: 0.25 } // with custom timing curve
		},
		
		childViews: "muteButton muteLabel volumeSlider".w(),
		
		volumeSlider: SC.View.design({
			didCreateLayer: function(){
				sc_super();
				
				this.updateTimer = SC.Timer.schedule({
					interval: 5000,
					target: this,
					action: "updateVolume",
					repeating: YES
				});
			},
			layout: {height: 312, width: 50, bottom: 55, centerX: -2},
			classNames: ["volume-slider"],
			
			transitions: {
				backgroundPositionY: {duration: 0.25}
			},
			
			dragging: NO,
			
			updateVolume: function(){
				//Tp5.log("Updating volume: %f", Tp5.volumeController.volume);
				Tp5.log("Setting to %s", sprintf("%.0f%%", Tp5.volumeController.volume*100));
				Tp5.volumeController.updateLastVolumeSet();
				this.$()[0].style.backgroundPositionY = sprintf("%.0f%%", 100-Tp5.volumeController.volume*100);
				//this.set("style", {backgroundPositionY: sprintf("%.0f%%", Tp5.volumeController.volume*100)});
			},
			
			mouseDown: function(){
				this.set('dragging', YES);
				this.updateTimer.invalidate();
				Tp5.appController.set('disableChanges', YES);
			},
			
			mouseUp: function(){
				this.set('dragging', NO);
				this.updateTimer = SC.Timer.schedule({
					interval: 500,
					target: this,
					action: "updateVolume",
					repeating: YES
				});
				Tp5.appController.set('disableChanges', NO);
			},
			
			mouseMoved: function(evt){
				if(this.dragging)
				{
					var h = evt.target.offsetHeight-36; //height of the draggable area; 36 found empirically
					var percent = (evt.clientY-evt.target.offsetTop-27)/h;
					if(percent < 0)percent = 0;
					if(percent > 1)percent = 1;
					SC.CoreQuery.find(".volume-slider")[0].style.backgroundPositionY = sprintf("%.1f%%", percent*100);
					Tp5.volumeController.set_volume(1-percent);
				}
			}
		}),
		
		muteButton: SC.View.design(Tp5.MouseHandlingFix, {
			classNames: ["overflow"],

			mouseClicked: function(){
				Tp5.volumeController.set_mute(!this.get('mute'));
			},
			
			mute: NO,
			
			muteChanged: function(){
				this.set('mute', Tp5.volumeController.mute);
			}.observes("Tp5.volumeController.mute"),

			displayProperties: 'mute'.w(),
			layout: {bottom: 25, centerX: 0, width: 60, height: 26},

			render: function(context, firstTime) {
				context = context.begin('div').addClass('control-button');
				context = context.begin('div').addClass('mute-overlay').end();
				if(this.get('mute'))
				{
					context = context.begin('div').addClass('mute-light').end();
				}
				context = context.end();
			}			
		}),
		
		muteLabel: SC.LabelView.design({
			layout: {bottom: 5, centerX: 0, width: 45, height: 15},
			value: "MUTE",
			textAlign: "center"
		})
		
	})
	
});
