// ==========================================================================
// Project:   WescontrolWeb.ControlPage
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
sc_require('views/device');
sc_require('views/device_control');

WescontrolWeb.ControlPage = SC.View.extend(
/** @scope WescontrolWeb.ControlPage.prototype */ {

	childViews: 'leftBar center rightBar'.w(),
	
	leftBar: SC.View.design({
		childViews: 'roomsLabel scrollView'.w(),
		layout: {left: 0, top:0, bottom: 0, width: 300},
		backgroundColor: "#EFEBE3",
		
		scrollView: SC.ScrollView.design(SC.Border, {
			borderStyle: SC.BORDER_NONE,
			hasHorizontalScroller: NO,
			layout: {top: 20, left: 0, right: 0, bottom: 0},
			contentView: SC.ListView.design({
				contentValueKey: "displayName",
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
	
	center: SC.ScrollView.design({
		layout: {right: 300, top:0, bottom:0, left: 300},
		borderStyle: SC.BORDER_NONE,
		hasHorizontalScroller: NO,
		contentView: SC.ListView.design({
			contentBinding: "WescontrolWeb.roomController",
			exampleView: WescontrolWeb.DeviceView,
			rowHeight: 80,
			selectionBinding: 'WescontrolWeb.roomController.selection',
			actsOnSelect: YES
		})
	}),
	
	rightBar: SC.ScrollView.design({
		layout: {right: 0, top:0, bottom:0, width: 300},
		backgroundColor: "#EFEBE3",
		borderStyle: SC.BORDER_NONE,
		hasHorizontalScroller: NO,
		contentView: WescontrolWeb.DeviceControlView.design({
			contentBinding: "WescontrolWeb.deviceController"
		})
	})

});
