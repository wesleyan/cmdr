// ==========================================================================
// Project:   WescontrolWeb.ControlPage
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
WescontrolWeb.ControlPage = SC.View.extend(
/** @scope WescontrolWeb.ControlPage.prototype */ {

	childViews: 'leftBar center rightBar'.w(),
	
	leftBar: SC.View.design({
		childViews: 'scrollView'.w(),
		layout: {left: 0, top:0, bottom: 0, width: 300},
		backgroundColor: "#EFEBE3",
		
		scrollView: SC.ScrollView.design(SC.Border, {
			borderStyle: SC.BORDER_NONE,
			hasHorizontalScroller: NO,
			layout: {top: 20, left: 0, right: 0, bottom: 0},
			contentView: SC.ListView.design({
				contentValueKey: "fullName",
				contentBinding: 'WescontrolWeb.roomController.arrangedObjects',
				rowHeight: 28,
				backgroundColor: "#EFEBE3"
			}).classNames('roomList')
		})
	}),
	
	rightBar: SC.View.design({
		layout: {right: 0, top:0, bottom:0, width: 300},
		backgroundColor: "#EFEBE3"
	}),
	
	center: SC.View.design({
		layout: {right: 300, top:0, bottom:0, left: 300},
	})

});
