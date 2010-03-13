// ==========================================================================
// Project:   Tp5 - mainPage
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

sc_require('views/top_bar');
sc_require('views/main');
sc_require('views/action_list');

// This page describes the main user interface for your application.  
Tp5.mainPage = SC.Page.design({

	// The main pane is made visible on screen as soon as your app is loaded.
	// Add childViews to this pane for views to display immediately on page
	// load.
	mainPane: SC.MainPane.design({
		childViews: 'topBar mainView'.w(),
		
		topBar: Tp5.TopBar.design({
			layout: {left: 0, right: 0, height: 90, top: 0}
		}),
		
		mainView: Tp5.MainView.design({
			layout: {left:0, right: 0, top: 90, bottom: 0},
			
			childViews: 'actionList'.w(),
			
			actionList: Tp5.ActionListView.design({
				layout: {left: 0, width: 400, bottom: 0, top:0}
			})
		})
	})

});
