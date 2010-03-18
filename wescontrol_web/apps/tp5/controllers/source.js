// ==========================================================================
// Project:   Tp5.sourceController
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your Controller Here)

  @extends SC.Object
*/


Tp5.sourceController = SC.ArrayController.create(
/** @scope Tp5.sourceController.prototype */ {

	projector: null,
	switcher: null,
	
	attempts: 0,
	attempt_source: null,
	
	contextView: null,
	
	setSource: function(name){
		var source = this.get('states')[name];
		if(source)this.set('source', source);
		else return NO;
	},
	
	sourceChanged: function(){
		//this code is to make sure that we don't just keep trying in vain to set the source,
		//as our feedback may not be working properly
		if(!this.get('source'))return;
		if(this.get('projector') && this.attempts < 3 || !this.attempt_source || this.attempt_source != this.get('source').name)
		{
			Tp5.log("Attempt #%d", this.attempts);
			this.projector.set_var("input", this.get('source').projector);
			this.attempts = this.attempts+1;
			if(this.attempts_source != this.get('source').name)this.attempts = 0;
			this.attempt_source = this.get('source').name;
		}

		if(this.get('switcher'))this.switcher.set_var("input", this.get('source').switcher);
		
		this.runCommands(this.get('source'));
		
		this.switchContext(this.get('source'));
		
	}.observes("source"),
	
	switcherChanged: function(){
		if(this.get('content').get('length') === 0)return;
		this.set("source", this.get('states')[this.switcher_map[this.switcher.get('states').input]]);
	}.observes("switcher", "states", ".switcher.states"),
	
	projectorPowerChanged: function(){
		if(this.get('content').get('length') === 0)return;
		if(this.projector.get('states').power == YES && this.get('source') && this.projector.get('states').power != this.old_projector_power)
		{
			var input = this.get('source').projector;
			if(input && this.projector.get('states').input != input)
			{
				this.projector.set_var("input", input);
			}
		}
		this.old_projector_power = this.projector.get('states').power;
	}.observes("projector", "states", ".projector.states"),
	
	contentChanged: function() {
		var states = {};
		var switcher_map = {};
		this.get('content').forEach(function(source){
			states[source.get('name')] = {
				guid: source.get('guid'),
				name: source.get('name'),
				projector: source.get('input').projector,
				switcher: source.get('input').switcher,
				commands: source.get('input').commands,
				context: source.get('input').context,
				image: source.get('icon')
			};
			switcher_map[source.get('input').switcher] = source.get('name');
		});
		this.set('switcher_map', switcher_map);
		this.set('states', states);
	}.observes("content"),
	
	runCommands: function(source){
		if(source && source.commands){
			source.commands.forEach(function(command){
				try {
					var device = Tp5.store.find(Tp5.Device, command.device);
					device.send_command(command.command, command.arg);
				}
				catch(e) {
					Tp5.log("Failed to run command %s: %s", command, e.message);
				}
			});
		}
	},
	
	switchContext: function(source){
		Tp5.log("Switching contexts to %s", source.context);
		if(source.context && Tp5[source.context])
		{
			this.set('contextView', Tp5[source.context].create({
				layout: {left: 0, right: 0, top: 0, bottom: 0}
			}));
			
		}
		else
		{
			this.set('contextView', null);
		}
	},
	
	projectorBinding: "Tp5.roomController.projector",
	switcherBinding: "Tp5.roomController.switcher"

}) ;
