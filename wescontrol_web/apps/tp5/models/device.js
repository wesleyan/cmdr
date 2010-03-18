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
	
	states: function() {
		var map = {};
		for(var key in this.get('state_vars'))
		{
			var state = this.get('state_vars')[key].state;
			if(state !== undefined)map[key] = state;
		}
		return map;
	}.property('state_vars').cacheable(),
	
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
	
	set_var: function(cvar, state) {
		try {
			var json = {};
			json[cvar] = state;
			SC.Request.postUrl('/devices/' + this.get('name'), json).json()
				.notify(this, "set_var_request_finished", cvar, state)
				.send();
		}
		catch(e){
			Tp5.log("JS Error when setting %s to %s: %s", cvar, state, e.message);
		}
	},
	
	set_var_request_finished: function(response, cvar, state) {
		var body = response.get('body');
		if(body.error){
			console.error("Failed to set %s to %s: %s", cvar, state, body.error);
		}
		else if(body[cvar]){
			Tp5.log("Attempted to set %s to %s, got %s", cvar, state, body[cvar]);
		}
	},
	
	send_command: function(command, arg){
		try {
			var json = {};
			json[command] = arg;
			SC.Request.postUrl('/devices/' + this.get('name') + '/command', json).json()
				.notify(this, "command_request_finished", command, arg)
				.send();
		}
		catch(e){
			Tp5.log("JS Error when executing command %s with %s: %s", command, arg, e.message);
		}
	},
	
	command_request_finished: function(response, command, arg){
		var body = response.get('body');
		if(body.error){
			console.error("Failed to run command %s with %s: %s", command, arg, body.error);
		}
		else if(body.result){
			Tp5.log("Attempted to run command %s with %s, got %s", command, arg, body.result);
		}
	}
}) ;

//extron = Tp5.Device.create({name: "extron"})
//extron.state_vars = {input: {type: 'option', editable: true, state: "3"}}
//extron.set_var("input", "2")