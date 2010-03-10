// ==========================================================================
// Project:   Tp5.VolumeButtonView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends Tp5.StatusButtonView
*/

sc_require('views/status_button');

Tp5.VolumeButtonView = Tp5.StatusButtonView.extend(
/** @scope Tp5.VolumeButtonView.prototype */ {

	childViews: "button controlDrawer imageView".w(),

	imageView: SC.ImageView.design({		
		layout: {left: 10, centerX: 0, width: 52, height: 52},
		value: sc_static("speaker.png")
	}),
	
	controlDrawer: SC.View.design(SC.Animatable, {
		classNames: ['control-drawer volume-control'],
		
		extendedHeight: 420,
			
		layout: {centerX:0, width: 70, top:2, bottom: 0},
		
		transitions: {
			height: { duration: 0.25 } // with custom timing curve
		}
		
	})
	
});
