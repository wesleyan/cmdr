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
	
	name: SC.Record.attr(String),
	building: SC.Record.toOne("WescontrolWeb.Building", {
		inverse: "rooms", isMaster: YES
	}),
	
	buildingName: function(){
		return this.getPath('building.name')
	}.property('building').cacheable(),
	
	fullName: function(){
		return this.getEach('buildingName', 'name').compact().join(' ');
	}.property('building', 'name').cacheable()
	
}) ;
