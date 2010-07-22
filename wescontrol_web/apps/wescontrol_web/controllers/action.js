// ==========================================================================
// Project:   WescontrolWeb.actionController
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your Controller Here)

  @extends SC.Object
*/

WescontrolWeb.actionController = SC.ArrayController.create(
/** @scope WescontrolWeb.actionController.prototype */ {

	contentBinding: "WescontrolWeb.roomListController.actions",
	roomBinding: "WescontrolWeb.roomListController",
		
	addNew: function() {
		// create a new task in the store
		console.log("Creating action");
		var action = WescontrolWeb.store.createRecord(WescontrolWeb.Action, {
			name: "unnamed",
			displayNameBinding: "name",
			belongs_to: this.get('room').get('guid'),
			promptProjector: true,
			source: null
		});

		this.selectObject(action);

		return YES;
	}

}) ;

WescontrolWeb.actionSelectionController = SC.ObjectController.create(
/** @scope WescontrolWeb.deviceController.prototype */ {

	contentBinding: SC.Binding.single('WescontrolWeb.actionController.selection')
	
}) ;
