// ==========================================================================
// Project:   Tp5.TopBar
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

sc_require('views/projector_button');

/** @class

  (Document Your View Here)

  @extends SC.View
*/
Tp5.TopBar = SC.View.extend(
/** @scope Tp5.TopBar.prototype */ {

	classNames: ['top-bar'],
	
	childViews: "roomLabel timeLabel projectorButton".w(),
	
	roomLabel: SC.LabelView.design({
		layout: {left: 20, centerY: 0, height: 50, width:100},
		//contentBinding: "Tp5.roomController.name"
		value: "Exley 509A",
		textAlign: "center"
	}).classNames('room-label'),
	
	timeLabel: SC.LabelView.design({
		layout: {right: 20, centerY: 0, height: 45, width: 70},
		valueBinding: "Tp5.appController.clock",
		textAlign: "center"
	}).classNames('time-label'),
	
	projectorButton: Tp5.ProjectorButtonView.design({
		layout: {left: 160, top: 5, height: 55, width: 113}
	})

});
