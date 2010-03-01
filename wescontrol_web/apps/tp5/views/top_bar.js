// ==========================================================================
// Project:   Tp5.TopBar
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
Tp5.TopBar = SC.View.extend(
/** @scope Tp5.TopBar.prototype */ {

	classNames: ['top-bar'],
	
	childViews: "roomLabel timeLabel".w(),
	
	roomLabel: SC.LabelView.design({
		layout: {left: 20, centerY: 0, height: 45, width:100},
		//contentBinding: "Tp5.roomController.name"
		value: "Exley 509A",
		textAlign: "center"
	}).classNames('roomLabel'),
	
	timeLabel: SC.LabelView.design({
		layout: {right: 20, centerY: 0, height: 45, width: 60},
		valueBinding: "Tp5.appController.clock",
		textAlign: "center"
	}).classNames('timeLabel')

});
