// ==========================================================================
// Project:   WescontrolWeb.configurationController
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your Controller Here)

  @extends SC.Object
*/
sc_require("views/general_configuration");
sc_require("views/devices_configuration");
WescontrolWeb.configurationController = SC.Object.create(
/** @scope WescontrolWeb.configurationController.prototype */ {

	currentTab: "devices",
	
	init: function(){
		this.onCurrentTabChange();
	},
	
	onCurrentTabChange: function(){
		console.log("Current view: %s", this.currentTab.capitalize() + "ConfigurationView");
		this.set("whatever", true);
		try {
			this.set('currentView', WescontrolWeb[this.currentTab.capitalize() + "ConfigurationView"].create({
				layout: {left: 0, right: 0, top: 0, bottom: 0}
			}));
		}
		catch (e){
			this.set('currentView', SC.View.create({
				layout: {left: 0, right: 0, top: 0, bottom: 0},
				childViews: "notImplementedLabel".w(),
				notImplementedLabel: SC.LabelView.create({
					layout: {centerX: 0, centerY: 0, width: 415, height: 30},
					value: "This feature is not yet implemented",
					color: "black"
				})
			}));
		}
	}.observes("currentTab")

}) ;
