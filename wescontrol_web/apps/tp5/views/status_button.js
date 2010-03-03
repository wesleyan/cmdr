// ==========================================================================
// Project:   Tp5.StatusButtonView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
Tp5.StatusButtonView = SC.View.extend(SC.Button,
/** @scope Tp5.StatusButtonView.prototype */ {

	classNames: ['status-button'],
	
	childViews: ['dropDown'],
	
	buttonBehavior: SC.PUSH_BEHAVIOR,
	
	dropDown: SC.View.design({
		
	})

});
