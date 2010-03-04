// ==========================================================================
// Project:   Tp5.ProjectorButtonView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
Tp5.ProjectorButtonView = SC.View.extend(SC.Animatable,
/** @scope Tp5.ProjectorButtonView.prototype */ {

	classNames: ['status-button'],
	
	childViews: "stateImage".w(),
	
	transitions: {
		height: { duration: 0.25 } // with custom timing curve
	},
			
	stateImage: SC.ImageView.design({
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
			
			return buttonImages[Tp5.deviceController.get('devices').projector.get('state_vars').state.state];
		}).from("Tp5.deviceController.devices.projector.state_vars")
		
	}),
	
	controlButtons: SC.View.extend({
		
	}),
	
	mouseDown: function(evt){
		//for some reason we have to have this to get mouse up events
	},
	
	mouseUp: function(evt){
		if(!this.drawerDown) {
			this.realHeight = this.layout.height;
			this.adjust("height", 200);
			this.drawerDown = YES;
		}
		else {
			this.adjust("height", this.realHeight);
			this.drawerDown = NO;
		}
	},
	
	drawerDown: NO

});