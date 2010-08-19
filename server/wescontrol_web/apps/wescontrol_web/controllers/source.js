// ==========================================================================
// Project:   WescontrolWeb.sourceController
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your Controller Here)

  @extends SC.Object
*/
WescontrolWeb.sourceController = SC.ArrayController.create(
/** @scope WescontrolWeb.sourceController.prototype */ {

	contentBinding: "WescontrolWeb.roomListController.sources",
	roomBinding: "WescontrolWeb.roomListController",
		
	addNew: function() {
		// create a new task in the store
		console.log("Creating source");
		var source = WescontrolWeb.store.createRecord(WescontrolWeb.Source, {
			name: "unnamed",
			displayNameBinding: "name",
			belongs_to: this.get('room').get('guid'),
			input: {}
		});

		this.selectObject(source);

		return YES;
	}

}) ;

WescontrolWeb.sourceSelectionController = SC.ObjectController.create(
/** @scope WescontrolWeb.deviceController.prototype */ {

	contentBinding: SC.Binding.single('WescontrolWeb.sourceController.selection')
	
}) ;

