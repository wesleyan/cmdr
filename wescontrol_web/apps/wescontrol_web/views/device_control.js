// ==========================================================================
// Project:   WescontrolWeb.DeviceControlView
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
WescontrolWeb.DeviceControlView = SC.View.extend(
/** @scope WescontrolWeb.DeviceControlView.prototype */ {

	childViews: 'deviceTitle'.w(),
	content: null,
	deviceTitle: SC.LabelView.design({
		layout: {left:0, right: 0, top: 10, height: 70},
		value: 'Projector',
		fontWeight: SC.BOLD_WEIGHT
	})

});
