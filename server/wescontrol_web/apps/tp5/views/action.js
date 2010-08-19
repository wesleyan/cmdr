// ==========================================================================
// Project:   Tp5.ActionView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
Tp5.ActionView = SC.View.extend(SC.ContentDisplay,
/** @scope Tp5.ActionView.prototype */ {

	classNames: ['action-view'],
	
	displayProperties: 'isSelected content'.w(),
	contentDisplayProperties: 'name'.w(),
	
	render: function(context, firstTime) {
		var content = this.get('content');
		var name = content.get('name');
		var icon = content.get('icon');
		
		var selected = this.get('isSelected');
		var standard = !selected;
		var classes = {'standard': standard, 'selected': selected};
		
		context = context.begin('div').addClass('action-view-item').setClass(classes);
		context = context.begin('div').addClass('action-icon').begin('img').attr('src', icon).end().end();
		context = context.begin('div').addClass('action-name').push(name).end();
		context = context.end();
		sc_super();
	}

});
