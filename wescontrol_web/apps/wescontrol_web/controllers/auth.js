// ==========================================================================
// Project:   WescontrolWeb.authController
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your Controller Here)

  @extends SC.Object
*/
WescontrolWeb.authController = SC.ObjectController.create(
/** @scope WescontrolWeb.authController.prototype */ {

	authenticated: false,
	_panelOpen: false,
	loginError: false,
	username: '',
	password: '',
	
	init: function(){
		SC.Timer.schedule({
			target: this,
			action: "testAuthentication",
			interval: 5000
		});
		this.testAuthentication();
		console.log("Authentication loaded");
		this.openPanel();
	},
	
	testAuthentication: function(){
		SC.Request.getUrl('/rooms').json()
			.notify(200, this, 'authSuccessful', null)
			.notify(400, this, 'authNowInvalid', null)
			.send();
	},
	
	login: function(){
		SC.Request.postUrl('/auth/login').json()
			.notify(200, this, 'authSuccessful')
			.notify(400, this, 'authFailed')
			.send({"username": this.username, "password": this.password});
	},
	
	authSuccessful: function(response){
		console.log("AuthSuccessful");
		console.log(response.get('body'));
		if(response.get('body') && response.get('body').auth_token)
		{
			var cookie = SC.Cookie.create({
				name: 'auth_token',
				value: response.get('body').auth_token,
				expires: 1
			});
			cookie.write();
		}
		this.set("authenticated", true);
		this.set("loginError", false);
		this.closePanel();
		WescontrolWeb.getPath('mainPage.mainPane').append() ;
	},
	
	authFailed: function(response){
		this.set("loginError", true);
	},
	
	authNowInvalid: function(response){
		console.log("Auth invalid");
		this.set("authenticated", false);
		/*this.login(this.username, this.password, function(success){
			if(!success)this.openPanel();
		});*/
	},
    
	openPanel: function(){
		if(this._panelOpen) return;
		this._panelOpen = true;
		this.set('loginError', false);
		console.log("opening panel");
		var panel = WescontrolWeb.getPath('login.panel');
		if(panel) {
			panel.append();
			panel.focus();
		}
	},
    
	closePanel: function(){
		console.log("Closing panel");
		this._panelOpen = false;
		var panel = WescontrolWeb.getPath('login.panel');
		if(panel) {
			panel.remove();
		}
	}    
}) ;
