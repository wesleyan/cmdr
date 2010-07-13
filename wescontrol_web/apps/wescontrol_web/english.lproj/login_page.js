// ==========================================================================
// Project:   WescontrolWeb.login
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

// This page describes a part of the interface for your application.
WescontrolWeb.login = SC.Page.design({
	panel: SC.PanelPane.create({
		layout: { top: 0, bottom: 0, left: 0, right: 0 },
		classNames: ['login-page'],

		contentView: SC.View.design({
			classNames: ['login-body'],
			layout: { centerX: 0, centerY: 0, width:400, height: 200 },
			childViews: "usernameField passwordField".w(),
		
			usernameField: SC.TextFieldView.design({
				layout: { top: 80, left: 60, right: 0, height: 32 },
				hint: "Username"
				//valueBinding: 'Tasks.loginController.loginName'
			}),
			passwordField: SC.TextFieldView.design({
				layout: { top: 126, left: 60, right: 0, height: 32 },
				isPassword: YES,
				hint: "Password"
			//	valueBinding: 'Tasks.loginController.password'
			})
		}),
		
		focus: function() {
			this.contentView.usernameField.becomeFirstResponder();        
		}
	})	
});
