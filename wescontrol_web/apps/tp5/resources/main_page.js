// ==========================================================================
// Project:   Tp5 - mainPage
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

sc_require('views/top_bar');
sc_require('views/main');

// This page describes the main user interface for your application.  
Tp5.mainPage = SC.Page.design({

	// The main pane is made visible on screen as soon as your app is loaded.
	// Add childViews to this pane for views to display immediately on page 
	// load.
	mainPane: SC.MainPane.design({
		childViews: 'topBar mainView'.w(),
		
		topBar: Tp5.TopBar.design({
			layout: {left: 0, right: 0, height: 64, top: 0}
		}),
		
		mainView: Tp5.MainView.design({
			layout: {left:0, right: 0, top: 64, bottom: 0}
		})
	})

});
