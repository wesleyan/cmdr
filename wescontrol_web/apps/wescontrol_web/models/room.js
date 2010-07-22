// ==========================================================================
// Project:   WescontrolWeb.Rooms
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document your Model here)

  @extends SC.Record
  @version 0.1
*/
WescontrolWeb.Room = SC.Record.extend(
/** @scope WescontrolWeb.Rooms.prototype */ {
	
	guid: SC.Record.attr(String),
	name: SC.Record.attr(String),
	building: SC.Record.toOne("WescontrolWeb.Building", {
		inverse: "rooms", isMaster: YES
	}),
	
	buildingName: function(){
		return this.getPath('building.name');
	}.property('building').cacheable(),
	
	fullName: function(){
		return this.getEach('buildingName', 'name').compact().join(' ');
	}.property('building', 'name').cacheable(),
	
	/*devices: SC.Record.toMany("WescontrolWeb.Device", {
		inverse: "room", isMaster: YES
	})*/
	
	devices: function(){
		return WescontrolWeb.store.find(SC.Query.local(WescontrolWeb.Device, {conditions: "room = {room}", room: this.get("guid")}));
	}.property("guid").cacheable(),
	
	sources: function(){
		return WescontrolWeb.store.find(SC.Query.local(WescontrolWeb.Source, {conditions: "belongs_to = {room}", room: this.get("guid")}));
	}.property("guid").cacheable(),
	
	actions: function(){
		return WescontrolWeb.store.find(SC.Query.local(WescontrolWeb.Action, {conditions: "belongs_to = {room}", room: this.get("guid")}));
	}.property("guid").cacheable(),
		
	couchHash: function(){
		var hash = {
			_id: this.get('guid'),
			_rev: this.get('_rev'),
			belongs_to: this.get('building').get("guid"),
			"class": "Room",
			attributes: {}
		};
		for(var key in this.attributes()){
			hash.attributes[key] = this.attributes()[key];
		}
		delete hash.attributes["building"];
		delete hash.attributes["_rev"];
		delete hash.attributes["guid"];
		return hash;
	}
	
	
}) ;
