// ==========================================================================
// Project:   WescontrolWeb.ConfigurePage
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
WescontrolWeb.ConfigurePage = SC.View.extend(
/** @scope WescontrolWeb.ConfigurePage.prototype */ {

	childViews: "textView".w(),
	textView: SC.LabelView.design({
		layout: {left:0, right:0, top:0, bottom:0},
		value: "CONFIGURE!!!"
	})

});
