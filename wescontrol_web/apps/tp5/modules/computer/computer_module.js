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

	didCreateLayer: function(){
		sc_super();
		this.onReachableChanged();
	},

	classNames: ['computer-module'],
	
	childViews: "titleLabel computerOffView computerOnView".w(),
	
	onReachableChanged: function(){
		if(Tp5.roomController.get('pc').get('states'))
		{
			console.log("ReachableChanged");
			this.computerOffView.set('isVisible', !Tp5.roomController.get('pc').get('states').reachable);
			this.computerOnView.set('isVisible', Tp5.roomController.get('pc').get('states').reachable);
		}
	}.observes("Tp5.roomController.pc.state_vars"),
	
	titleLabel: SC.LabelView.design({
		layout: {top: 20, left: 0, right: 0, height: 50},
		value: "Computer",
		textAlign: "center"
	}).classNames("title"),
	
	computerOffView: SC.View.design({
		layout: {top: 90, left: 10, right: 10, bottom: 10},
		childViews: "offLabel onButton".w(),
		classNames: 'computer-off',
		isVisible: NO,
		
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
		})		
	}),
	
	computerOnView: SC.View.design({
		layout: {top: 90, left: 10, right: 10, bottom: 10},
		childViews: "label".w(),
		isVisible: NO,
		
		label: SC.LabelView.design({
			layout: {top: 0, left:0, right:0, height: 38},
			classNames: 'computer-on-label title',
			value: "computer is on",
			textAlign: "center"
		})
	})
});
