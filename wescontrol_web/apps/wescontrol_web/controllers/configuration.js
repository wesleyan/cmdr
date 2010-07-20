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
sc_require("views/sources_configuration");
sc_require("views/preview_configuration");
WescontrolWeb.configurationController = SC.Object.create(
/** @scope WescontrolWeb.configurationController.prototype */ {

	currentTab: "sources",
	
	graphValue: "",
	
	configDirty: NO,
	
	init: function(){
		this.onCurrentTabChange();
	},
	
	updateDirty: function(){
		var dirty = 0;
		dirty += WescontrolWeb.deviceController.get('status') & SC.Record.DIRTY;
		dirty += WescontrolWeb.sourceSelectionController.get('status') & SC.Record.DIRTY;
		dirty += WescontrolWeb.roomListController.get('status') & SC.Record.DIRTY;
		if(dirty != 0){
			this.set("configDirty", YES);
		}
	}.observes(
		"WescontrolWeb.deviceController.status",
		"WescontrolWeb.sourceSelectionController.status",
		"WescontrolWeb.roomListController.status"
	),
	
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
	
	/*generateGraph: function(){
		if(WescontrolWeb.roomController.get('content') && WescontrolWeb.sourceController.get('content'))
		{
			SC.Request.postUrl('/graph').json()
				.notify(this, "graphGenerated")
				.send({
					devices: WescontrolWeb.roomController.get('content').mapProperty('attributes'),
					sources: WescontrolWeb.sourceController.get('content').mapProperty('attributes')
				});
		}
	}.observes("WescontrolWeb.deviceController.content", 
		"WescontrolWeb.sourceSelectionController.content",
		"WescontrolWeb.sourceController.hasContent",
		"WescontrolWeb.roomController.hasContent"),
	
	graphGenerated: function(response){
		this.set('graphValue', "data:image/svg+xml;base64," + response.get('body')["data"]);
	}*/
	

}) ;
