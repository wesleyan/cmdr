// ==========================================================================
// Project:   Tp5.SourceButtonView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends Tp5.StatusButtonView
*/

sc_require('views/status_button');
sc_require('views/button');

Tp5.SourceButtonView = Tp5.StatusButtonView.extend(
/** @scope Tp5.SourceButtonView.prototype */ {

	childViews: "button controlDrawer imageView".w(),

	imageView: SC.ImageView.design({		
		layout: {left: 15, top: 3, maxHeight: 50, maxWidth: 80},
		//value: sc_static("on.png")

		valueBinding: SC.Binding.transform(function(value, binding) {
			return Tp5.sourceController.source.image;
		}).from("Tp5.sourceController.source")
	}),
	
	controlDrawer: SC.View.design(SC.Animatable, {
		classNames: ['control-drawer'],
		
		extendedHeight: 180,
			
		layout: {left:0, right:0, top:0, bottom: 0},
		
		transitions: {
			height: { duration: 0.25 } // with custom timing curve
		},
		
		sourcesUpdated: function(){
			var childViews = [];
			var self = this;
			var top = 65;
			Tp5.log("Sources updated: %d", Tp5.sourceController.get('content').get('length'));
			Tp5.sourceController.get('content').forEach(function(source){
				childViews.push(self.createChildView(Tp5.ButtonView.design({
					layout: {left: 5, right: 5, top: top, height: 35},
					
					action: function(){
						Tp5.mainPage.mainPane.topBar.sourceButton.button.mouseClicked();
						Tp5.sourceController.setSource(source.get('name'));
					},
					
					value: source.get('name')
				})));
				top += 35+10;
			});
			this.extendedHeight = top;
			this.replaceAllChildren(childViews);
		}.observes('Tp5.sourceController.states')		
	})
	
});
