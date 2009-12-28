// ==========================================================================
// Project:   WescontrolWeb.Device
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document your Model here)

  @extends SC.Record
  @version 0.1
*/
WescontrolWeb.Device = SC.Record.extend(
/** @scope WescontrolWeb.Device.prototype */ {

	room: SC.Record.toOne("WescontrolWeb.Room", {
		inverse: "devices", isMaster: NO
	}),
	
	vars_obj: function() {
		var vars_array = [];
		for(var key in this.get('state_vars'))
		{
			var obj = this.get('state_vars')[key];
			obj.name = key;
			vars_array.pushObject(obj);
		}
		return vars_array;
	}.property('state_vars').cacheable()

}) ;
