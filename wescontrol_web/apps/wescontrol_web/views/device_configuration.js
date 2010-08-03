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
			displaName = name.humanize().titleize();
			var valueChanged = function(){
				var config = WescontrolWeb.deviceController.get('config');
				if(!config)config = {};
				if(config[name] != this.get('value')){
					config[name] = this.get('value');
					WescontrolWeb.deviceController.set('config', config);
				}
			};
			var configChanged = function(){
				var config = WescontrolWeb.deviceController.get('config');
				if(config)this.set('value', config[name]);
			};
			if(c_var.type == "port")
			{
				childViews.push(newThis.createChildView(SC.View.design({
					layout: {left: 0, right: 0, top: 50*heightCounter++, height: 40},
					childViews: "label field".w(),
					label: SC.LabelView.design({
						layout: {left:0, width: 200, height: 30, top: 0},
						value: displaName.capitalize()
					}),

					field: SC.SelectFieldView.design({
						layout: {left: 220, height: 20, width: 200, top: 0},
						objectsBinding: "WescontrolWeb.roomListController.ports",
						nameKey: "name",
						valueKey: "value",
						disableSort: true,
						emptyName: false,
						theme: 'square',
						valueChanged: valueChanged.observes('value'),
						configChanged: configChanged.observes('WescontrolWeb.deviceController.config')
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
						value: displaName.capitalize()
					}),

					field: SC.TextFieldView.design({
						layout: {left: 220, height: 20, width: 200, top: 0},
						isPassword: c_var.type == "password",
						validator: c_var.type == "integer" ? "Number" : null,
						valueChanged: valueChanged.observes('value'),
						configChanged: configChanged.observes('WescontrolWeb.deviceController.config')
					})				
				})));
			}
		});
		this.replaceAllChildren(childViews);
	}.observes('hasContent', 'content', 'WescontrolWeb.deviceController.driver', 'WescontrolWeb.driverController.currentType')
	


});
