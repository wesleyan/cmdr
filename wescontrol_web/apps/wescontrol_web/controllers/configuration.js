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
WescontrolWeb.configurationController = SC.Object.create(
/** @scope WescontrolWeb.configurationController.prototype */ {

	currentTab: "general",
	
	init: function(){
		this.onCurrentTabChange();
	},
	
	onCurrentTabChange: function(){
		console.log("Current view: %s", this.currentTab.capitalize() + "ConfigurationView");
		this.set("whatever", true);
		this.set('currentView', WescontrolWeb[this.currentTab.capitalize() + "ConfigurationView"].create({
			layout: {left: 0, right: 0, top: 0, bottom: 0}
		}));
	}.observes("currentTab")

}) ;
