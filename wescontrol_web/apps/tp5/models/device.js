// ==========================================================================
// Project:   Tp5.Device
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document your Model here)

  @extends SC.Record
  @version 0.1
*/
Tp5.Device = SC.Record.extend(
/** @scope WescontrolWeb.Device.prototype */ {

	room: SC.Record.toOne("WescontrolWeb.Room", {
		inverse: "devices", isMaster: NO
	}),
	
	name: SC.Record.attr(String),
	
	editable: SC.Record.attr(Boolean, {defaultValue: YES}),
	
	vars_obj: function() {
		var vars_array = [];
		for(var key in this.get('state_vars'))
		{
			var obj = this.get('state_vars')[key];
			obj.name = key;
			obj.name = obj.name.replace("_", " ");
			vars_array.pushObject(obj);
		}
		return vars_array;
	}.property('state_vars').cacheable(),
	
	controllable_vars: function() {
		return this.get('vars_obj').filter(function(item){
			return (item.editable === undefined || item.editable);
		}).sortProperty('display_order');
	}.property('vars_obj').cacheable()

}) ;
