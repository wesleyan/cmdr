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
		
		//this.addObject(device);

		// select new task in UI
		this.selectObject(device);

		/* activate inline editor once UI can repaint
		this.invokeLater(function() {
		var contentIndex = this.indexOf(task);
		var list = Todos.mainPage.getPath('mainPane.middleView.contentView');
		var listItem = list.itemViewForContentIndex(contentIndex);
		listItem.beginEditing();
		});*/

		return YES;
	}
  
		
}) ;
