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
			source: true
		};
		for(var key in this.attributes()){
			hash[key] = this.attributes()[key];
		};
		delete hash["guid"];
		delete hash["icon"];
		return hash;
	}

}) ;
