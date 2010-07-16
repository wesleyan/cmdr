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
			childViews: "usernameField passwordField loginErrorMessage loginButton".w(),
		
			usernameField: SC.TextFieldView.design({
				layout: { top: 80, left: 60, right: 0, height: 32 },
				hint: "Username",
				valueBinding: 'WescontrolWeb.authController.username'
			}),
			
			passwordField: SC.TextFieldView.design({
				layout: { top: 126, left: 60, right: 0, height: 32 },
				isPassword: YES,
				hint: "Password",
				valueBinding: 'WescontrolWeb.authController.password'
			}),
			
			loginErrorMessage: SC.LabelView.design({
				layout: { top: 175, left: 70, width: 220, height: 20 },
				classNames: ['error-message'],
				value: "Invalid username/password",
				isVisibleBinding: SC.Binding.oneWay('WescontrolWeb.authController.loginError').bool()
			}),

			loginButton: SC.ButtonView.design({
				layout: { bottom: 0, right: 0, width: 80, height: 24 },
				titleMinWidth: 0,
				isEnabledBinding: SC.Binding.oneWay('WescontrolWeb.loginController.username').bool(),
				isDefault: YES,
				title: "Login",
				target: 'WescontrolWeb.authController',
				action: 'login'
			})
		}),
		
		focus: function() {
			this.contentView.usernameField.becomeFirstResponder();        
		}
	})	
});
