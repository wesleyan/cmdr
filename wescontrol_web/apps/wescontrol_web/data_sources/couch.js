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
		/*console.log("Create record");
		var hash = store.readDataHash(storeKey);
		if (SC.kindOf(store.recordTypeFor(storeKey), this.appObject.Device)) {
			console.log("Creating record: %s", hash.name);
			SC.Request.putUrl('/rooms/' + this.randomUUID).json()
				.notify(this, this.didCreateDoc, store, storeKey)
				.send({
					belongs_to: hash.room,
					attributes: {
						state_vars: {},
						name: hash.name
					},
					device: YES,
					"class": hash.driver
				});
			return YES;
		}*/
		
		WW.log("updating record");
		var hash = store.readDataHash(storeKey);
		if(SC.kindOf(store.recordTypeFor(storeKey), WW.device())){
			WW.log("Updating device: %s", hash.name);
			WW.log(hash);
		}
		// TODO: Add handlers to submit modified record to the data source
		// call store.dataSourceDidComplete(storeKey) when done.

		return NO ; // return YES if you handled the storeKey
	}
});