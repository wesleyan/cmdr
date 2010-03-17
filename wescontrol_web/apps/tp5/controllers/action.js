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
	
	allowsMultipleSelection: NO,
	
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
		if(this.get('hasSelection'))this.doAction(this.get('selection').get('firstObject'));
	}.observes("selection"),
	
	sourceChanged: function(){
		if(this.get('hasSelection') && Tp5.sourceController.get('source') &&
			Tp5.sourceController.get('source').name != this.get('selection').get('firstObject').get('settings').source)
		{
			this.set('selection', SC.SelectionSet.EMPTY);
		}
	}.observes("Tp5.sourceController.source")
}) ;
