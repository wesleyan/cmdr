// ==========================================================================
// Project:   Tp5.ActionView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
sc_require('lib/mouse_handling');
sc_require('views/button');

Tp5.ComputerModule = SC.View.extend(Tp5.MouseHandlingFix,
/** @scope Tp5.ActionView.prototype */ {

	classNames: ['computer-module'],
	
	childViews: "titleLabel computerOffView".w(),
	
	titleLabel: SC.LabelView.design({
		layout: {top: 20, left: 0, right: 0, height: 50},
		value: "Computer",
		textAlign: "center"
	}).classNames("title"),
	
	computerOffView: SC.View.design({
		layout: {top: 90, left: 10, right: 10, bottom: 10},
		childViews: "offLabel onButton".w(),
		classNames: 'computer-off',
		
		init: function(){
			sc_super();
			this.onReachableChanged();
		},
		
		offLabel: SC.LabelView.design({
			layout: {top: 0, left:0, right: 0, height: 38},
			classNames: "computer-off-label title",
			value: "Error: computer is off",
			textAlign: "center"
		}),
		
		onButton: Tp5.ButtonView.design({
			layout: {centerX: 0, width:250, height: 40, top: 80},
			value: "Attempt to turn on",
			action: function(){
				Tp5.roomController.get('pc').send_command("start");
			}
		}),
		
		onReachableChanged: function(){
			if(Tp5.roomController.get('pc').get('states'))
			{
				this.set('isVisible', !Tp5.roomController.get('pc').get('states').reachable);
			}
		}.observes("Tp5.roomController.pc.state_vars")
		
	})
});
