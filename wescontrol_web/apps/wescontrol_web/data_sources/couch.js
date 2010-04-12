// ==========================================================================
// Project:		WescontrolWeb.CouchDataSource
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

	(Document Your Data Source Here)

	@extends SC.DataSource
*/

// ==========================================================================
// Project:		Tp5.CouchDataSource
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 CouchDataSource */

/** @class

	(Document Your Data Source Here)

	@extends SC.DataSource
*/

sc_require('lib/couch');

WescontrolWeb.CouchDataSource = CouchDataSource.extend({
	appObject: WescontrolWeb,
	
	disableChangesBinding: "WescontrolWeb.appController.disableChanges",
	
	fetchedBuildingsCallback: function(response){
		WescontrolWeb.buildingController.refreshSources();			
		//WescontrolWeb.roomController.set('content', Tp5.store.find(Tp5.Room, Tp5.appController.roomID));
	},
	
	fetchedSourcesCallback: function(response){
		//WescontrolWeb.sourceController.contentChanged();
	}
});