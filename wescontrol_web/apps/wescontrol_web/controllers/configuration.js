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
sc_require("views/confirm_configuration");
sc_require("views/action_configuration");
WescontrolWeb.configurationController = SC.Object.create(
/** @scope WescontrolWeb.configurationController.prototype */ {
	
	CLEAN_STATE: 0,
	DIRTY_STATE: 1,
	COMMITTING_STATE: 2,
	ERROR_STATE: 3,

	currentTab: 'sources',
	
	graphValue: '',
	
	viewCache: {},
	
	commitCount: 0,
	
	configDirty: function(){
		return this.state == this.DIRTY_STATE || this.state == this.COMMITTING_STATE;
	}.property('state'),
	
	state: 0,
	
	commitError: '',
	
	init: function(){
		this.onCurrentTabChange();
	},
	
	updateDirty: function(){
		if(this.get('state') == this.CLEAN_STATE)
		{
			var dirty = 0;
			dirty += WescontrolWeb.deviceController.get('status') & SC.Record.DIRTY;
			dirty += WescontrolWeb.sourceSelectionController.get('status') & SC.Record.DIRTY;
			dirty += WescontrolWeb.roomListController.get('status') & SC.Record.DIRTY;
			dirty += WescontrolWeb.actionSelectionController.get('status') & SC.Record.DIRTY;
			if(dirty != 0)this.set("state", this.DIRTY_STATE);
		}
	}.observes(
		"WescontrolWeb.deviceController.status",
		"WescontrolWeb.sourceSelectionController.status",
		"WescontrolWeb.roomListController.status",
		"WescontrolWeb.actionSelectionController.status"
	),
	
	onCurrentTabChange: function(){
		//try {
			var tabName = this.currentTab.capitalize() + "ConfigurationView";
			if(!this.viewCache[tabName]){
				this.viewCache[tabName] = WescontrolWeb[tabName].create({
					layout: {left: 0, right: 0, top: 0, bottom: 0}
				});
			}
			this.set('currentView', this.viewCache[tabName]);
		/*}
		catch (e){
			console.log("Loading tab failed");
			console.log(e);
			this.set('currentView', SC.View.create({
				layout: {left: 0, right: 0, top: 0, bottom: 0},
				childViews: "notImplementedLabel".w(),
				notImplementedLabel: SC.LabelView.create({
					layout: {centerX: 0, centerY: 0, width: 415, height: 30},
					value: "This feature is not yet implemented",
					color: "black"
				})
			}));
		}*/
	}.observes("currentTab"),
	
	saveConfiguration: function(){
		console.log("Saving configuration");
		if(WescontrolWeb.deviceController.get('status') & SC.Record.DIRTY){
			WescontrolWeb.deviceController.get('content').commitRecord();
			this.commitCount++;
		}
		if(WescontrolWeb.roomListController.get('status') & SC.Record.DIRTY){
			WescontrolWeb.roomListController.get('content').commitRecord();
			this.commitCount++;
		}
		if(WescontrolWeb.sourceSelectionController.get('status') & SC.Record.DIRTY){
			WescontrolWeb.sourceSelectionController.get('content').commitRecord();
			this.commitCount++;
		}
		if(WescontrolWeb.actionSelectionController.get('status') & SC.Record.DIRTY){
			WescontrolWeb.actionSelectionController.get('content').commitRecord();
			this.commitCount++;
		}
		if(this.commitCount != 0)this.set('state', this.COMMITTING_STATE);
	},
	
	watchCommitCount: function(){
		if(this.state == this.COMMITTING_STATE && this.commitCount == 0){
			this.set('state', this.CLEAN_STATE);
		}
	}.observes('commitCount')
	
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
