// ==========================================================================
// Project:   Tp5.ContextAreaView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
sc_require('views/projector_overlay');
sc_require('modules/dvd/dvd_module.js');

Tp5.ContextAreaView = SC.View.extend(
/** @scope Tp5.ContextAreaView.prototype */ {
	
	classNames: ["context-area"],

	childViews: 'projectorOverlay contextModule'.w(),
	
	projectorOverlay: Tp5.ProjectorOverlayView.design({
		layout: {bottom: -70, left:0, right:0, height: 70},
		visibleBinding: "Tp5.appController.projectorOverlayVisible"
	}),
	
	contextModule: SC.ContainerView.design({
		layout: {top: 0, bottom: 0, left: 0, right: 0},
		contentViewBinding: "Tp5.sourceController.contextView"
	})

});
