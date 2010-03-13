// ==========================================================================
// Project:   Tp5.actionController
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your Controller Here)

  @extends SC.ArrayController
*/
Tp5.actionController = SC.ArrayController.create(
/** @scope Tp5.actionController.prototype */ {

	lastAction: null,
	
	doAction: function(action){
		this.set('lastAction', action);
	}

}) ;
