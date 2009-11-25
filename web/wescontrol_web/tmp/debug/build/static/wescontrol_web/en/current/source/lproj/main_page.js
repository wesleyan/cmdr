// ==========================================================================
// Project:		WescontrolWeb - mainPage
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

// This page describes the main user interface for your application.	
WescontrolWeb.mainPage = SC.Page.design({

	// The main pane is made visible on screen as soon as your app is loaded.
	// Add childViews to this pane for views to display immediately on page 
	// load.
	mainPane: SC.MainPane.design({
		childViews: 'topBar mainView bottomBar'.w(),

		topBar: SC.View.design({
			layout: {top: 0, left: 0, right: 0, height: 72},
			backgroundColor: "#333333"
		}).classNames("topBar"),
		
		mainView: SC.View.design({
			childViews: 'leftBar center rightBar'.w(),
			layout: {top: 72, left: 0, right:0, bottom: 72},
			backgroundColor: "#ffffff",
			
			leftBar: SC.View.design({
				layout: {left: 0, top:0, bottom: 0, width: 300},
				backgroundColor: "#EFEBE3"
			}),
			
			rightBar: SC.View.design({
				layout: {right: 0, top:0, bottom:0, width: 300},
				backgroundColor: "#EFEBE3"
			}),
			
			center: SC.View.design({
				layout: {right: 300, top:0, bottom:0, left: 300},
			})
			
		}),
		
		bottomBar: SC.View.design({
			layout: {bottom: 0, left: 0, right: 0, height: 72},
			backgroundColor: "#333333"
		})
		
	})

});
; if ((typeof SC !== 'undefined') && SC && SC.scriptDidLoad) SC.scriptDidLoad('wescontrol_web');