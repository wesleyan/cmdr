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
		
	sourceChanged: function(){
		this.set("state", this.states[this.get("source")]);
		if(this.projector)this.projector.set_var("input", this.state.projector);
		if(this.switcher)this.switcher.set_var("input", this.state.switcher);
	}.observes("source"),
	
	switcherChanged: function(){
		this.set("source", this.states[this.switcher_map[this.switcher.get("input")]]);
	}.observes("switcher.input"),
	
	projectorPowerChanged: function(){
		if(this.projector.get("power") == YES)
		{
			this.projector.set_var("input", this.state.projector);
		}
	}.observes("projector.power"),
	
	contentChanged: function() {
		
		this.states = {};
		this.switcher_map = {};
		this.get('content').forEach(function(source){
			this.states[source.name] = {
				projector: source.input.projector,
				switcher: source.input.switcher,
				image: source.image
			};
			this.switcher_map[source.input.switcher] = source.name;
		});
		
	}.observes("content")

}) ;
