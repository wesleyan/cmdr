// ==========================================================================
// Project:   WescontrolWeb.PreviewConfigurationView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
WescontrolWeb.PreviewConfigurationView = SC.View.extend(
/** @scope WescontrolWeb.PreviewConfigurationView.prototype */ {

	childViews: "webView".w(),
	
	webView: SC.WebView.design({
		layout: {centerX: 0, centerY: 0, width: 800, height: 480},
		value: "http://localhost:4020/tp5"
	})

});
