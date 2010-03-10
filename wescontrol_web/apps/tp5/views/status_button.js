// ==========================================================================
// Project:   Tp5.StatusButtonView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends SC.View
*/

sc_require('mouse_handling');

Tp5.ControlButtonView = SC.View.extend(Tp5.MouseHandlingFix, {
	
	classNames: ["overflow"],
	
	mouseClicked: function(){
		if(this.disableStates.indexOf(this.state) == -1)
		{
			this.action();
		}
	},
		
	action: function(){
		//override this to do something
	},
	
	//add states to this to disable the button on those states
	disableStates: [],
	
	statesChanged: function(){
		this.set('state', Tp5.deviceController.get('devices').projector.get('state_vars').state.state);
	}.observes("Tp5.deviceController.devices.projector.state_vars"),
	
	displayProperties: 'state value'.w(),
	
	render: function(context, firstTime) {
		context = context.begin('div').addClass('control-button');
		if(this.disableStates.indexOf(this.state) != -1)context.addClass('disabled');
		context = context.begin('div').addClass('label').push(this.value).end().end();
	}
	
});


Tp5.StatusButtonView = SC.View.extend(SC.Animatable,
/** @scope Tp5.StatusButtonView.prototype */ {

	classNames: ['status-button'],
	
	childViews: "button controlDrawer".w(),
	
	button: SC.View.design(Tp5.MouseHandlingFix, {
		classNames: ['button'],
		layout: {left: 0, right:0, top: 0, bottom: 0},
		
		mouseClicked: function(){
			if(!this.drawerDown) {
				this.parentView.controlDrawer.realHeight = this.parentView.layout.height;
				this.parentView.controlDrawer.adjust("height", this.parentView.controlDrawer.extendedHeight);
				this.drawerDown = YES;
			}
			else {
				this.parentView.controlDrawer.adjust("height", this.parentView.controlDrawer.realHeight);
				this.drawerDown = NO;
			}
		},

		drawerDown: NO
	}),
	
	controlDrawer: SC.View.design(SC.Animatable, {
		classNames: ['control-drawer'],
		
		layout: {left:0, right:0, top:0, bottom: 0},
		
		transitions: {
			height: { duration: 0.25 } // with custom timing curve
		}
	})
				

});
