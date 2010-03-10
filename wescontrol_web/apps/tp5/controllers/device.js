// ==========================================================================
// Project:   Tp5.deviceController
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your Controller Here)

  @extends SC.Object
*/
Tp5.deviceController = SC.ArrayController.create(
/** @scope Tp5.deviceController.prototype */ {

	contentChanged: function() {
		
		var devices = {};
		console.log("Setting devices on %d", this.get('content').get('length'));
		this.get('content').forEach(function(device){
			console.log("Adding %s", device.get('name'));
			devices[device.get('name')] = device;
			
			//TODO: This is definitely not the best way to do this.
			if(device.get('name') == "projector")Tp5.sourceController.set('projector', device);
			if(device.get('name') == "extron")Tp5.sourceController.set('switcher', device);
		});
		
		this.devices = devices;
		
	},
	
	refreshContent: function() {
		console.log("Refreshing");
		this.set('content', Tp5.store.find(Tp5.Device));
		this.contentChanged();
	}

}) ;
