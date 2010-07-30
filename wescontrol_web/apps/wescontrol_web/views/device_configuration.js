// ==========================================================================
// Project:   WescontrolWeb.DeviceConfigurationView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
WescontrolWeb.DeviceConfigurationView = SC.View.extend(
/** @scope WescontrolWeb.DeviceConfigurationView.prototype */ {

	classNames: ['device-configuration-view'],
	content: null,
	
	updateContent: function() {
		var childViews = [], view;
		this.replaceAllChildren(childViews);
		if(!this.get('content'))return;
		
		var newThis = this;
		var driver = this.get('content').get('driverRecord');
		if(!driver || !driver.get('config'))return;
		var heightCounter = 0;
		console.log("Updating with %s", driver.get('name'));
		_(driver.get('config')).each(function(c_var, name){
			name = name.humanize().titleize();
			if(c_var.type == "port")
			{
				childViews.push(newThis.createChildView(SC.View.design({
					layout: {left: 0, right: 0, top: 50*heightCounter++, height: 40},
					childViews: "label field".w(),
					label: SC.LabelView.design({
						layout: {left:0, width: 200, height: 30, top: 0},
						value: name.capitalize()
					}),

					field: SC.SelectFieldView.design({
						layout: {left: 220, height: 20, width: 200, top: 0},
						valueBinding: "WescontrolWeb.deviceController.config." + name,
						objectsBinding: "WescontrolWeb.roomListController.ports",
						nameKey: "name",
						valueKey: "value",
						disableSort: true,
						emptyName: false,
						theme: 'square'
					})				
				})));
			}
			else if(c_var.type == "integer" || c_var.type == "string" || c_var.type == "password")
			{
				childViews.push(newThis.createChildView(SC.View.design({
					layout: {left: 0, right: 0, top: 50*heightCounter++, height: 40},
					childViews: "label field".w(),
					label: SC.LabelView.design({
						layout: {left:0, width: 200, height: 30, top: 0},
						value: name.capitalize()
					}),

					field: SC.TextFieldView.design({
						layout: {left: 220, height: 20, width: 200, top: 0},
						valueBinding: "WescontrolWeb.deviceController.config." + name,
						isPassword: c_var.type == "password",
						validator: c_var.type == "integer" ? "Number" : null
					})				
				})));
			}
		});
		this.replaceAllChildren(childViews);
	}.observes('hasContent', 'content', 'WescontrolWeb.deviceController.driver', 'WescontrolWeb.deviceController.currentType')
	


});
