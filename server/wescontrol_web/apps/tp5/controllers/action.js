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
	
	actionPerformedLast: null,
	
	doAction: function(action){
		this.set('lastAction', action);
		if(action.get('settings').source){
			var source = Tp5.store.find(Tp5.Source, action.get('settings').source);
			if(source)Tp5.sourceController.setSource(source.get('name'));
		}
		if(action.get('settings').prompt_projector){
			var projector = Tp5.roomController.get('projector');
			if(projector && !projector.get('states').power)
			{
				Tp5.appController.set('projectorOverlayVisible', YES);
				if(this.hideTimer)this.hideTimer.invalidate();
				this.hideTimer = SC.Timer.schedule({
					target: Tp5.appController, 
					action: function(){ this.set('projectorOverlayVisible', NO);}, 
					interval: 15*1000
				});
			}
		}
		this.actionPerformedLast = SC.DateTime.create().get('milliseconds');
		
	},
	
	selectionChanged: function(){
		if(this.get('hasSelection'))this.doAction(this.get('selection').get('firstObject'));
	}.observes("selection"),
	
	sourceChanged: function(){
		if(this.get('hasSelection') && Tp5.sourceController.get('source') &&
			Tp5.sourceController.get('source').guid != this.get('selection').get('firstObject').get('settings').source)
		{
			//only deselect if it's been less than three seconds since you chose
			if(this.actionPerformedLast && SC.DateTime.create().get('milliseconds')-this.actionPerformedLast > 3000)
			{
				this.set('selection', SC.SelectionSet.EMPTY);
			}
		}
	}.observes("Tp5.sourceController.source")
}) ;
