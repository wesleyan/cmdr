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
	
	setSource: function(name){
		var source = this.get('states')[name];
		if(source)this.set('source', source);
		else return NO;
	},
	
	sourceChanged: function(){
		//this code is to make sure that we don't just keep trying in vain to set the source,
		//as our feedback may not be working properly
		if(this.get('projector') && this.attempts < 3 || !this.attempt_source || this.attempt_source != this.get('source').name)
		{
			Tp5.log("Attempt #%d", this.attempts);
			this.projector.set_var("input", this.get('source').projector);
			this.attempts = this.attempts+1;
			if(this.attempts_source != this.get('source').name)this.attempts = 0;
			this.attempt_source = this.get('source').name;
		}

		if(this.get('switcher'))this.switcher.set_var("input", this.get('source').switcher);
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
				name: source.get('name'),
				projector: source.get('input').projector,
				switcher: source.get('input').switcher,
				image: source.get('icon')
			};
			switcher_map[source.get('input').switcher] = source.get('name');
		});
		this.set('switcher_map', switcher_map);
		this.set('states', states);
	}.observes("content"),
	
	projectorBinding: "Tp5.roomController.projector",
	switcherBinding: "Tp5.roomController.switcher"

}) ;
