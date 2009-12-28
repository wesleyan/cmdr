// ==========================================================================
// Project:		WescontrolWeb - mainPage
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

SC.Binding.selectedIfTrue = function(){
	return this.transform(function(value, binding) {
		return value ? "tabButton selected" : "tabButton not-selected";
	}) ;
} ;


// This page describes the main user interface for your application.	
WescontrolWeb.mainPage = SC.Page.design({

	// The main pane is made visible on screen as soon as your app is loaded.
	// Add childViews to this pane for views to display immediately on page 
	// load.
	mainPane: SC.MainPane.design({
		childViews: 'topBar mainView bottomBar'.w(),

		topBar: SC.View.design({
			childViews: 'tabBar'.w(),
			layout: {top: 0, left: 0, right: 0, height: 72},
			backgroundColor: "#333333",
						
			tabBar: SC.View.design({
				childViews: 'controlButton monitorButton configureButton'.w(),
				layout: {top: 0, left: 0, width: 140*2+175, height: 72},
				
				controlButton: WescontrolWeb.TabButton.design({
					displayTitle: 'Control',
					layout: {bottom: 0, left:0, width:140, height: 40},
					action: "function(){SC.RunLoop.begin(); WescontrolWeb.appController.set('currentTab', 'control'); SC.RunLoop.end();}",
					isSelectedBinding: SC.Binding.oneWay("WescontrolWeb.appController.currentTab").isEqualTo("control")
				}).classNames("tan"),
				
				monitorButton: WescontrolWeb.TabButton.design({
					displayTitle: 'Monitor',
					layout: {bottom: 0, left:140, width:140, height: 40},
					action: "function(){SC.RunLoop.begin(); WescontrolWeb.appController.set('currentTab', 'monitor'); SC.RunLoop.end();}",
					isSelectedBinding: SC.Binding.oneWay("WescontrolWeb.appController.currentTab").isEqualTo("monitor")
				}),
				
				configureButton: WescontrolWeb.TabButton.design({
					displayTitle: 'Configure',
					layout: {bottom: 0, left: 140*2, width: 175, height: 40},
					action: "function(){SC.RunLoop.begin(); WescontrolWeb.appController.set('currentTab', 'configure'); SC.RunLoop.end();}",
					isSelectedBinding: SC.Binding.oneWay("WescontrolWeb.appController.currentTab").isEqualTo("configure")
				})
			})
		}).classNames("topBar"),
		
		mainView: SC.View.design({
			childViews: 'scenes'.w(),
			layout: {top: 72, left: 0, right:0, bottom: 72},
			backgroundColor: "#ffffff",
			
			scenes: SC.SceneView.design({
				layout: {left: 0, top: 0, bottom:0, right: 0},
				scenes: 'control monitor configure'.w(),
				nowShowingBinding: "WescontrolWeb.appController.currentTab"
			})
			
						
		}),
		
		bottomBar: SC.View.design({
			layout: {bottom: 0, left: 0, right: 0, height: 72},
			backgroundColor: "#333333"			
		})
		
	}),
	control: WescontrolWeb.ControlPage.design({
		layout: {left: 0, top: 0, bottom:0, right: 0}
	}),
	monitor: WescontrolWeb.MonitorPage.design({
		layout: {left: 0, top: 0, bottom:0, right: 0}
	}),
	configure: WescontrolWeb.ConfigurePage.design({
		layout: {left: 0, top: 0, bottom:0, right: 0}
	})
	

});
