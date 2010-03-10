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

Tp5.CouchDataSource = CouchDataSource.extend({
	appObject: Tp5,
	
	fetchedBuildingsCallback: function(response){
		Tp5.deviceController.refreshContent();
		Tp5.roomController.set('content', Tp5.store.find(Tp5.Room, Tp5.appController.roomID));
	},
	
	fetchedSourcesCallback: function(response){
		Tp5.sourceController.contentChanged();
	}
});
