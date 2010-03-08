// ==========================================================================
// Project:   Tp5.MouseHandlingFix
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  this is a mixin that fixes SC's built-in broken mouse handling

  @extends SC.Object
*/

Tp5.MouseHandlingFix = {
	
	//override this to get mouse events
	mouseClicked: function(){},
	
	mouseInside: NO,
		
	mouseDown: function(){
		return YES;
	},
	
	mouseUp: function(){		
		if(this.mouseInside)
		{
			this.mouseClicked();
		}
		return YES;
	},
	
	mouseExited: function(evt) {
		this.set('mouseInside', NO);
		return YES;
	},
	
	mouseEntered: function(evt){
		this.set('mouseInside', YES);
		return YES;
	}
	
};