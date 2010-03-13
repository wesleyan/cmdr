// ==========================================================================
// Project:   Tp5.ProjectorOverlayView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
sc_require('views/button');
Tp5.ProjectorOverlayView = SC.View.extend(
/** @scope Tp5.ProjectorOverlayView.prototype */ {
	
	classNames: "projector-overlay".w(),

	childViews: "projectorLabel yesButton noButton".w(),
	
	projectorLabel: SC.LabelView.design({
		layout: {left: 15, width: 190, centerY: 0, height: 50},
		value: "Would you like to use the projector?",
		fontWeight: 700
	}),
	
	yesButton: Tp5.ButtonView.design({
		layout: {left: 215, width:68, height: 45, centerY: 0},
		value: "yes"
	}),
	
	noButton: Tp5.ButtonView.design({
		layout: {left: 300, width: 68, height: 45, centerY: 0},
		value: "no"
	}),
	
	onVisibilityChange: function(){
		
	}

});
