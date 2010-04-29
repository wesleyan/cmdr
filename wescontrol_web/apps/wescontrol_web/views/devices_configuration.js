// ==========================================================================
// Project:   WescontrolWeb.DeviceConfigurationView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your View Here)

  @extends SC.View
*/

sc_require('views/crud_list.js');

WescontrolWeb.DevicesConfigurationView = SC.View.extend(
/** @scope WescontrolWeb.DeviceConfigurationView.prototype */ {

	classNames: ["device-configuration"],
	
	childViews: "deviceList deviceEdit".w(),
	
	deviceList: WescontrolWeb.CrudList.design({
		layout: {top: 0, bottom: 0, left: 0, width: 200},
		contentBinding: "WescontrolWeb.roomController"
	}),
	
	deviceEdit: SC.View.design({
		layout: {top: 0, bottom: 0, left: 200, right: 0},
		childViews: "deviceForm".w(),
		
		deviceForm: SC.View.design({
			layout: {centerX: 0, width: 320, top: 40, bottom: 40},
			
			childViews: "name port type driver".w(),
			
			name: SC.View.design({
				layout: {left: 0, right: 0, top: 0, height: 40},
				childViews: "nameLabel nameField".w(),
				nameLabel: SC.LabelView.design({
					layout: {left:0, width: 100, height: 30, top: 0},
					value: "Name"
				}),
				
				nameField: SC.TextFieldView.design({
					layout: {left: 120, height: 30, width: 200, top: 0},
					valueBinding: "WescontrolWeb.deviceController.name"
				})
			}),
			
			port: SC.View.design({
				layout: {left: 0, right: 0, top: 50, height: 40},
				childViews: "portLabel portField".w(),
				portLabel: SC.LabelView.design({
					layout: {left:0, width: 100, height: 30, top: 0},
					value: "Port"
				}),
				
				portField: SC.SelectFieldView.design({
					layout: {left: 120, height: 20, width: 200, top: 0},
					valueBinding: "WescontrolWeb.deviceController.port",
					objectsBinding: "WescontrolWeb.roomListController.ports",
					nameKey: "name",
					valueKey: "value",
					disableSort: true,
					emptyName: false,
					theme: 'square'
				})				
			}),
			type: SC.View.design({
				layout: {left: 0, right: 0, top: 100, height: 40},
				childViews: "typeLabel typeField".w(),
				typeLabel: SC.LabelView.design({
					layout: {left:0, width: 100, height: 30, top: 0},
					value: "Type"
				}),
				
				typeField: SC.SelectFieldView.design({
					layout: {left: 120, height: 20, width: 200, top: 0},
					objectsBinding: "WescontrolWeb.driverController.arrangedObjects",
					nameKey: "name",
					valueKey: "name",
					disableSort: true,
					emptyName: false,
					theme: 'square',
					driverChanged: function(){
						var dr = WescontrolWeb.deviceController.get('driverRecord');
						if(dr)this.set('value', dr.get('type'));
					}.observes('WescontrolWeb.deviceController.driverRecord'),
					changed: function(){
						WescontrolWeb.driverController.set('currentType', this.get('value'));
					}.observes('value')
				})				
			}),
			driver: SC.View.design({
				layout: {left: 0, right: 0, top: 150, height: 40},
				childViews: "driverLabel driverField".w(),
				driverLabel: SC.LabelView.design({
					layout: {left:0, width: 100, height: 30, top: 0},
					value: "Driver"
				}),
				
				driverField: SC.SelectFieldView.design({
					layout: {left: 120, height: 20, width: 200, top: 0},
					valueBinding: "WescontrolWeb.deviceController.driver",
					objectsBinding: "WescontrolWeb.driverController.arrangedDrivers",
					nameKey: "name",
					valueKey: "name",
					disableSort: true,
					emptyName: false,
					theme: 'square'
				})				
			})
			
			
		})
		
	})

});
