// ==========================================================================
// Project:   Tp5
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

// This is the function that will start your app running.  The default
// implementation will load any fixtures you have created then instantiate
// your controllers and awake the elements on your page.
//
// As you develop your application you will probably want to override this.
// See comments for some pointers on what to do next.
//
Tp5.main = function main() {

	// Step 1: Instantiate Your Views
	// The default code here will make the mainPane for your application visible
	// on screen.  If you app gets any level of complexity, you will probably 
	// create multiple pages and panes.  
	Tp5.getPath('mainPage.mainPane').append() ;

	// Step 2. Set the content property on your primary controller.
	// This will make your app come alive!

	// TODO: Set the content property on your primary controller
	// ex: Tp5.contactsController.set('content',Tp5.contacts);
	Tp5.store.find(Tp5.Building);
	Tp5.deviceController.set('content', Tp5.store.find(Tp5.Device));
	Tp5.sourceController.set('content', Tp5.store.find(Tp5.Source));
	//var query = SC.Query.local(Tp5.Room, 'mac = {mac_addr}', {mac_addr: '00:30:1b:82:ac:39'});
	//Tp5.roomController.set('content', Tp5.store.find(query));
} ;

function main() { Tp5.main(); }