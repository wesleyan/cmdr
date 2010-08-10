// ==========================================================================
// Project:   WescontrolWeb.MonitorPage
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
WescontrolWeb.MonitorPage = SC.View.extend(
/** @scope WescontrolWeb.MonitorPage.prototype */ {

	childViews: "leftBar".w(),
	leftBar: SC.View.design({
		childViews: 'roomsLabel scrollView'.w(),
		layout: {left: 0, top:0, bottom: 0, width: 300},
		backgroundColor: "#EFEBE3",
		
		scrollView: SC.ScrollView.design(SC.Border, {
			borderStyle: SC.BORDER_NONE,
			hasHorizontalScroller: NO,
			layout: {top: 20, left: 0, right: 0, bottom: 0},
			contentView: SC.ListView.design({
				contentValueKey: "name",
				contentBinding: 'WescontrolWeb.buildingController.arrangedObjects',
				selectionBinding: 'WescontrolWeb.buildingController.selection',
				rowHeight: 28,
				backgroundColor: null,
				actOnSelect: YES
			}).classNames('roomList')
		}),
		
		roomsLabel: SC.LabelView.design({
			layout: {left:0, right: 0, bottom:0, height: 70},
			value: "Rooms",
			fontWeight: SC.BOLD_WEIGHT
		}).classNames('backgroundText')
	}),
	

});
