// ==========================================================================
// Project:   WescontrolWeb.Action
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document your Model here)

  @extends SC.Record
  @version 0.1
*/
WescontrolWeb.Action = SC.Record.extend(
/** @scope WescontrolWeb.Action.prototype */ {

	couchHash: function(){
		var hash = {
			_id: this.get('guid'),
			action: true
		};
		for(var key in this.attributes()){
			hash[key] = this.attributes()[key];
		};
		delete hash["guid"];
		return hash;
	},
	
	setPromptProjector: function(value){
		if(this.get("settings") && this.get("settings").promptProjector != value){
			console.log("Setting promptProjector to");
			console.log(value);
			this.get("settings").prompt_projector = value;
			this.recordDidChange("settings");
		}
	},
	
	setSource: function(value){
		if(this.get("settings") && this.get("settings").source != value){
			this.get("settings").source = value;
			this.recordDidChange("settings");
		}
	}

}) ;
