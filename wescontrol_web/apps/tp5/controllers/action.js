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
		if(action.get('settings').source){
			Tp5.sourceController.setSource(action.get('settings').source);
		}
		if(action.get('settings').prompt_projector){
			Tp5.appController.set('projectorOverlayVisible', YES);
			if(this.hideTimer)this.hideTimer.invalidate();
			this.hideTimer = SC.Timer.schedule({
				target: Tp5.appController, 
				action: function(){ this.set('projectorOverlayVisible', NO);}, 
				interval: 15*1000
			});
		}
	},
	
	selectionChanged: function(){
		Tp5.log("Selection changed to");
		Tp5.log(this.get('selection'));
		this.doAction(this.get('selection').get('firstObject'));
	}.observes("selection")

}) ;
