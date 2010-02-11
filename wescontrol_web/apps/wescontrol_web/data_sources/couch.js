// ==========================================================================
// Project:		WescontrolWeb.CouchDataSource
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

	(Document Your Data Source Here)

	@extends SC.DataSource
*/
WescontrolWeb.CouchDataSource = SC.DataSource.extend(
/** @scope WescontrolWeb.CouchDataSource.prototype */ {
	
	init: function(){
		sc_super();
		this.comet = SC.Object.create({
			doRequest: function(since){
				console.log("Doing request: %d", since);
				SC.Request.getUrl('/rooms/_changes?feed=longpoll&filter=wescontrol_web/device&since=' + since).json()
					.notify(this, "requestFinished", since)
					.send();
			},
			
			requestFinished: function(response, since){
				var body = response.get('body');
				if(body.results){
					body.results.forEach(function(doc){
						SC.Request.getUrl('/rooms/' + doc['id']).json()
							.notify(this, 'fetchedChangedRecord')
							.send();
					});
					since = body.last_seq;
				}
				this.doRequest(since);
			},
			
			fetchedChangedRecord: function(response){
				var body = response.get('body');
				if(body)
				{
					console.log("%s changed", body['_id']);
					var device = WescontrolWeb.store.find(WescontrolWeb.Device, body._id);
					device.set('state_vars', body.attributes.state_vars);
				}
			}
		});
		
		WescontrolWeb.store.find(WescontrolWeb.Building);
		
		this.comet.doRequest(0);
	},

	// ..........................................................
	// QUERY SUPPORT
	// 

	fetch: function(store, query) {

		// TODO: Add handlers to fetch data for specific queries.	 
		// call store.dataSourceDidFetchQuery(query) when done.
		console.log("Calling for " + query.recordType);
		if(query.recordType == WescontrolWeb.Building) {
			SC.Request.getUrl('/rooms/_design/wescontrol_web/_view/building').json()
				.notify(this, 'didFetchBuildings', store, query)
				.send();
			return YES;
		}
		/*else if(query.recordType == WescontrolWeb.Device)
		{
			SC.Request.getUrl('/rooms/_design/wescontrol_web/_view/device').json()
				.notify(this, 'didFetchDevices', store, query)
				.send();
			return YES;
		}*/

		return NO ; // return YES if you handled the query
	},
	didFetchDevices: function(response, store, query){
		if(SC.ok(response)) {
			store.loadRecords(WescontrolWeb.Device, response.get('body').rows.mapProperty('value'));
			store.dataSourceDidFetchQuery(query);
		}
		else {
			store.dataSourceDidErrorQuery(query, response);
		}
	},
	didFetchBuildings: function(response, store, query){
		if (SC.ok(response)) {
			var buildings = [];
			var rooms = [];
			var room_hash = {};
			var devices = [];
			var last_building = null;
			response.get('body').rows.forEach(function(row){
				if(row.key[1] === 0) //this is a building
				{
					last_building = row.value;
					last_building["rooms"] = [];
					buildings.push(last_building);
				}
				else if(row.key[1] === 1)
				{
					last_building.rooms.push(row.value.guid);
					rooms.push(row.value);
					room_hash[row.value.guid] = row.value;
				}
				else if(row.key[1] === 2)
				{
					room_hash[row.value.room].devices.push(row.value.guid);
					devices.push(row.value);
				}
			});
			store.loadRecords(WescontrolWeb.Building, buildings);
			store.loadRecords(WescontrolWeb.Room, rooms);
			store.loadRecords(WescontrolWeb.Device, devices);
			store.dataSourceDidFetchQuery(query);
			WescontrolWeb.buildingController.refreshSources();
		}
		else {
			store.dataSourceDidErrorQuery(query, response);
		}
	},

	// ..........................................................
	// RECORD SUPPORT
	// 
	
	retrieveRecord: function(store, storeKey) {
		
		// TODO: Add handlers to retrieve an individual record's contents
		// call store.dataSourceDidComplete(storeKey) when done.
		
		return NO ; // return YES if you handled the storeKey
	},
	
	createRecord: function(store, storeKey) {
		
		// TODO: Add handlers to submit new records to the data source.
		// call store.dataSourceDidComplete(storeKey) when done.
		
		return NO ; // return YES if you handled the storeKey
	},
	
	updateRecord: function(store, storeKey) {
		
		// TODO: Add handlers to submit modified record to the data source
		// call store.dataSourceDidComplete(storeKey) when done.

		return NO ; // return YES if you handled the storeKey
	},
	
	destroyRecord: function(store, storeKey) {
		
		// TODO: Add handlers to destroy records on the data source.
		// call store.dataSourceDidDestroy(storeKey) when done
		
		return NO ; // return YES if you handled the storeKey
	}
	
}) ;
