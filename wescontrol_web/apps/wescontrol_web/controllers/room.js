// ==========================================================================
// Project:   WescontrolWeb.roomController
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your Controller Here)

  @extends SC.Object
*/
WescontrolWeb.roomController = SC.ArrayController.create(
/** @scope WescontrolWeb.roomController.prototype */ {
	
	contentBinding: "WescontrolWeb.roomListController.devices",
	roomBinding: "WescontrolWeb.roomListController",
		
	addNew: function() {
		// create a new task in the store
		console.log("Creating device");
		var device = WescontrolWeb.store.createRecord(WescontrolWeb.Device, {
			name: "unnamed",
			displayNameBinding: "name",
			room: this.get('room').get('guid')
		});

		this.selectObject(device);

		return YES;
	}
  
		
}) ;
