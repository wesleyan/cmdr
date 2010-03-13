// ==========================================================================
// Project:   Tp5.ProjectorButtonView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends Tp5.StatusButtonView
*/

sc_require('views/status_button');

Tp5.ProjectorButtonView = Tp5.StatusButtonView.extend(
/** @scope Tp5.ProjectorButtonView.prototype */ {
	childViews: "button controlDrawer imageView".w(),

	imageView: SC.ImageView.design({		
		layout: {centerX: 0, top: 3, width: 68, height: 80},
		//value: sc_static("on.png")

		valueBinding: SC.Binding.transform(function(value, binding) {
			//this may look strange, but it's necessary because of how SC does static resources
			var buttonImages = {
				on: sc_static('on.png'),
				off: sc_static('off.png'),
				muted: sc_static('muted.png'),
				cooling: sc_static('cooling.png'),
				warming: sc_static('warming.png')
			};
			var image = buttonImages[Tp5.deviceController.get('devices').projector.get('states').state];
			Tp5.log("image");
			return image? image : buttonImages.off;
		}).from("Tp5.deviceController.devices.projector.state_vars")
	}),
	
	controlDrawer: SC.View.design(SC.Animatable, {
		classNames: ['control-drawer'],
		
		extendedHeight: 180,
		
		childViews: "onoffButton muteButton".w(),
		
		layout: {left:0, right:0, top:0, bottom: 0},
		
		transitions: {
			height: { duration: 0.25 } // with custom timing curve
		},
		
		onoffButton: Tp5.ControlButtonView.design({
			layout: {left: 5, right: 5, bottom: 65, height: 35},
			
			action: function(){
				var state = Tp5.deviceController.get('devices').projector.get("states").state;
				Tp5.deviceController.devices.projector.set_var("power", state == "off");
				Tp5.mainPage.mainPane.topBar.projectorButton.button.mouseClicked();
			},
			
			valueBinding: SC.Binding.transform(function(value, binding){
				var state = Tp5.deviceController.get('devices').projector.get('states').state;
				if(["on", "muted", "warming"].indexOf(state) != -1)return "off";
				else return "on";
			}).from("Tp5.deviceController.devices.projector.state_vars"),
			
			disableStates: ["warming", "cooling"]

		}),
		
		muteButton: Tp5.ControlButtonView.design({
			layout: {left: 5, right: 5, bottom: 15, height: 35},
			
			action: function(){
				var state = Tp5.deviceController.get('devices').projector.get('states').state;
				Tp5.deviceController.devices.projector.set_var("video_mute", state != "muted");
				Tp5.mainPage.mainPane.topBar.projectorButton.button.mouseClicked();
			},
			
			valueBinding: SC.Binding.transform(function(value, binding){
				var state = Tp5.deviceController.get('devices').projector.get('state_vars').state.state;
				return state == "muted" ? "unmute" : "mute";
			}).from("Tp5.deviceController.devices.projector.state_vars"),
			
			disableStates: ["warming", "cooling", "off"]
		})
		
	})
	
});