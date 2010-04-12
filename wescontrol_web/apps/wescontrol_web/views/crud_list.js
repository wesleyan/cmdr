// ==========================================================================
// Project:   WescontrolWeb.CrudList
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
WescontrolWeb.CrudList = SC.View.extend(
/** @scope WescontrolWeb.CrudList.prototype */ {
	
	classNames: "crud-list",

	childViews: "listView bottomBar".w(),
		
	listView: SC.ListView.design({
		layout: {left: 0, right: 0, top: 0, bottom: 38},
		contentValueKey: "name",
		rowHeight: 46,
		contentBinding: ".parentView.content",
		selectionBinding: ".parentView.content.selection"
	}),
	
	bottomBar: SC.View.design({
		classNames: "crud-bottom-bar",
		layout: {left: 0, right: 0, bottom: 0, height: 38},
		childViews: "addButton deleteButton".w(),
		
		addButton: SC.ButtonView.design({
			layout: {right: 0, top: 0, bottom: 0, width: 52},
			theme: "none",
			displayTitle: "+",
			target: "WescontrolWeb.roomController",
			action: "addNew"
		}),
		
		deleteButton: SC.ButtonView.design({
			layout: {right: 53, top: 0, bottom: 0, width: 52},
			theme: "none",
			displayTitle: "&ndash;"
		}).classNames("delete")
	})

});
