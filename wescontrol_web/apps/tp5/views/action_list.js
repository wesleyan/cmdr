// ==========================================================================
// Project:   Tp5.ActionListView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

sc_require('views/action');

/** @class

  (Document Your View Here)

  @extends SC.View
*/
Tp5.ActionListView = SC.View.extend(
/** @scope Tp5.ActionListView.prototype */ {

	classNames: "action-list-view".w(),
	
	childViews: "titleView actionList".w(),
	
	titleView: SC.View.design({
		layout: {left: 0, right: 0, height: 50, top: 0},
		
		childViews: "titleText".w(),
		
		titleText: SC.LabelView.design({
			layout: {top: 10, left: 0, right: 0, height: 42},
			value: "What would you like to do?",
			textAlign: "center"
			
		}).classNames("title-text")
		
	}).classNames("title-view"),
	
	actionList: SC.ScrollView.design({
		layout: {top: 50, bottom: 0, left: 0, right: 0},
		borderStyle: SC.BORDER_NONE,
		hasHorizontalScroller: NO,
		contentView: SC.ListView.design({
			contentBinding: "Tp5.actionController",
			exampleView: Tp5.ActionView,
			rowHeight: 65,
			selectionBinding: 'Tp5.actionController.selection',
			actsOnSelect: YES
		})
	}).classNames("action-list")
	
});
