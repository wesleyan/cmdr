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

	childViews: "textView".w(),
	textView: SC.LabelView.design({
		layout: {left:0, right:0, top:200, bottom:0},
		value: "MONITOR!!!",
		backgroundColor: "black"
	})

});
