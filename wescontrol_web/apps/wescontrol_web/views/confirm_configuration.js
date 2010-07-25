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
	
	childViews: "confirmBox progressBox successfulBox".w(),

	confirmBox: SC.View.design({
		childViews: "confirmLabel confirmButton".w(),
		layout: {centerY: 0, width: 380, height: 140, centerX: 0},
		isVisibleBinding: SC.Binding.oneWay("WescontrolWeb.configurationController.state").isEqualTo(1),
		confirmLabel: SC.LabelView.design({
			layout: {top: 0, centerX: 0, width: 380, height: 70},
			value: "Are you sure you want to send this configuration to the device?"
		}),

		confirmButton: SC.ButtonView.design({
			layout: {top: 90, centerX: 0, width: 100, height: 50},
			title: "Save",
			theme: "square",
			action: "WescontrolWeb.configurationController.saveConfiguration"
		})
	}),
	progressBox: SC.View.design({
		childViews: "progressLabel progressBar".w(),
		layout: {centerY: 0, width: 410, height: 140, centerX: 0},
		isVisibleBinding: SC.Binding.oneWay("WescontrolWeb.configurationController.state").isEqualTo(2),
		progressLabel: SC.LabelView.design({
			layout: {top: 0, centerX: 0, width: 410, height: 30},
			value: "Sending configuration to device..."
		}),
		progressBar: SC.ProgressView.design({
			layout: {top: 60, centerX: 0, width: 250, height: 20},
			isIndeterminate: YES,
			isRunning: YES
		})
	}),
	successfulBox: SC.LabelView.design({
		layout: {centerY: 0, centerX: 0, width: 380, height: 40},
		value: "Changes successfully saved",
		isVisibleBinding: SC.Binding.oneWay("WescontrolWeb.configurationController.state").isEqualTo(0)
	})
});
