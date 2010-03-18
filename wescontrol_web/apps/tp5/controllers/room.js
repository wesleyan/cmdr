// ==========================================================================
// Project:   Tp5.roomController
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your Controller Here)

  @extends SC.Object
*/
Tp5.roomController = SC.ObjectController.create(
/** @scope Tp5.roomController.prototype */ {
	
	updateAttributes: function(){
		Tp5.log("Content updated");
		if(this.get('content') && this.get('content').get('attributes'))
		{
			Tp5.log("And not null");
			var attributes = Tp5.roomController.get('content').get('attributes').attributes;
			this.set('attributes', attributes);
			var devices = Tp5.deviceController.get('devices');
			if(devices)
			{
				Tp5.log("Setting devices");
				this.set('volume', devices[attributes.volume]);
				this.set('projector', devices[attributes.projector]);
				this.set('switcher', devices[attributes.switcher]);
				this.set('dvdplayer', devices["dvdplayer"]);
			}
		}
	}.observes('content') //, 'Tp5.deviceController.devices')


}) ;
