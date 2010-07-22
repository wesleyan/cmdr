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
	
	fetchedDriversCallback: function(response){
		WescontrolWeb.driverController.refreshSources();
	},
	
	updateRecord: function(store, storeKey) {
		console.log("updating record");
		var hash = store.readDataHash(storeKey);
		var rt = store.recordTypeFor(storeKey);
		if(SC.kindOf(rt, WescontrolWeb.Device) ||
			SC.kindOf(rt, WescontrolWeb.Room) ||
			SC.kindOf(rt, WescontrolWeb.Source))
		{
			SC.Request.putUrl('/rooms/' + hash.guid).json()
				.notify(this, this.didCommitRecord, store, storeKey)
				.send(store.materializeRecord(storeKey).couchHash());
			return YES;
		}
		return NO ; // return YES if you handled the storeKey
	},
	
	didCommitRecord: function(response, store, storeKey){
		var body = response.get('body');
		console.log(body);
		if(SC.ok(response) && body["ok"]){
			var attrs = store.materializeRecord(storeKey);
			attrs["_rev"] = body.rev;
			store.dataSourceDidComplete(storeKey);
		}
		else {
			console.log("Commit failed");
		}
		
	}
});