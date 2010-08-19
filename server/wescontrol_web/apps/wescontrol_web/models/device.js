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

	/*room: SC.Record.toOne("WescontrolWeb.Room", {
		inverse: "devices", isMaster: NO
	}),*/
	
	/*configurationChanged: function(){
		for(var config in this.get("configuration"))
		{
			this[config] = function(key, value) { 
				var config_var = this.get(config); 
				if (value !== undefined)
				{
					config_var = Object.clone(config_var) ; // make a copy with the edit... 
					config_var.first = value; 
					this.set(config, config_var); 
				} 
				return config_var.first; 
			}.property(config);
		}
	}.observes("attributes"),*/
	
	room: SC.Record.attr(String),
	
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
	}.property('vars_obj').cacheable(),
	
	driverRecord: function(){
		if(this.get('driver')){
			return WescontrolWeb.store.find(SC.Query.local(WescontrolWeb.Driver, 'name = {name}', {name: this.get('driver')})).firstObject();
		}
	}.property('driver').cacheable(),
	
	couchHash: function(){
		var hash = {
			_id: this.get('guid'),
			_rev: this.get('_rev'),
			belongs_to: this.get('room'),
			device: YES,
			"class": this.get('driver'),
			attributes: {}
		};
		for(var key in this.attributes()){
			hash.attributes[key] = this.attributes()[key];
		}
		delete hash.attributes["room"];
		delete hash.attributes["_rev"];
		delete hash.attributes["guid"];
		delete hash.attributes["driver"];
		return hash;
	}
}) ;
