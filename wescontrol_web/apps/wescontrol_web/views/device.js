// ==========================================================================
// Project:   WescontrolWeb.DeviceView
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
WescontrolWeb.DeviceView = SC.View.extend(SC.ContentDisplay,
/** @scope WescontrolWeb.DeviceView.prototype */ {

	classNames: ['device-list-item-view'],
	
	contentDisplayProperties: 'name'.w(),
	
	displayProperties: 'isSelected'.w(),
	
	render: function(context, firstTime) {
		var content = this.get('content');
		var name = content.get('name');
		var vars = content.get('vars_obj').filterProperty('displayOrder').sortProperty('displayOrder');
		
		var selected = this.get('isSelected');
		var standard = !selected;
		var classes = {'standard': standard, 'selected': selected};
		
		context = context.begin('div').addClass('device-view-item').setClass(classes);
		context = context.begin('div').addClass('device-name').push(name).end();
		context = context.begin('div').addClass('device-statevars');
		
		context = context.begin('table').addStyle({position: 'absolute', top: '50%', marginTop: '-34px;'});
		vars.slice(0, 3).forEach(function(state_var){
			context = context.begin('tr');
			context = context.begin('td').addClass('var-name').push(state_var.name).end();
			context = context.begin('td').addClass('var-state').push(state_var.state).end();
			context = context.end();
		});
		context = context.end();
		context = context.begin('table').addStyle({position: 'absolute', top: '50%', marginTop: '-34px', left: '150px'});
		vars.slice(3, 6).forEach(function(state_var){
			context = context.begin('tr');
			context = context.begin('td').addClass('var-name').push(state_var.name).end();
			context = context.begin('td').addClass('var-state').push(state_var.state).end();
			context = context.end();
		});
		context = context.end().end().end();
		sc_super();
	}

});
