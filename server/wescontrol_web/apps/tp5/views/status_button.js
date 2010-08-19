// ==========================================================================
// Project:   Tp5.StatusButtonView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends SC.View
*/

sc_require('lib/mouse_handling');


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
