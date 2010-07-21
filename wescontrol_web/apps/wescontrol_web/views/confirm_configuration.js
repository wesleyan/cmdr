// ==========================================================================
// Project:   WescontrolWeb.ConfirmConfigurationView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
WescontrolWeb.ConfirmConfigurationView = SC.View.extend(
/** @scope WescontrolWeb.ConfirmConfigurationView.prototype */ {

	childViews: "confirmBox successfulBox".w(),
	confirmBox: SC.View.design({
		childViews: "confirmLabel confirmButton".w(),
		layout: {centerY: 0, width: 380, height: 140, centerX: 0},
		isVisibleBinding: "WescontrolWeb.configurationController.configDirty",
		confirmLabel: SC.LabelView.design({
			layout: {top: 0, centerX: 0, width: 380, height: 70},
			value: "Are you sure you want to send this configuration to the device?"
		}),

		confirmButton: SC.ButtonView.design({
			layout: {top: 90, centerX: 0, width: 100, height: 50},
			title: "Save",
			//controlSize: SC.HUGE_CONTROL_SIZE,
			theme: "square",
			action: "WescontrolWeb.configurationController.saveConfiguration"
		})
	}),
	successfulBox: SC.LabelView.design({
		layout: {centerY: 0, centerX: 0, width: 380, height: 40},
		value: "Changes successfully saved",
		isVisibleBinding: SC.Binding.not("WescontrolWeb.configurationController.configDirty")
	})
});
