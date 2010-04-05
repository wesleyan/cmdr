// ==========================================================================
// Project:   WescontrolWeb.GeneralConfigurationView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
WescontrolWeb.GeneralConfigurationView = SC.View.extend(
/** @scope WescontrolWeb.GeneralConfigurationView.prototype */ {
	
	classNames: "general-configuration",
	
	childViews: "generalSettings".w(),
	
	generalSettings: SC.View.design({
		layout: {left: 0, right: 0, height: 100},
		
		childViews: "nameField buildingField".w(),
		
		nameField: SC.View.design({
			layout: {centerX: -200, width:250, height:38, top: 30},
			childViews: "nameLabel nameField".w(),
			
			nameLabel: SC.LabelView.design({
				layout: {left:0, width: 80, height:38, centerY: 0},
				value: "Name:"
			}),
			
			nameField: SC.TextFieldView.design({
				layout: {left: 100, right:0, height: 38, centerY:0},
				valueBinding: SC.Binding.single("WescontrolWeb.deviceController.content.name")
			})
		}),
		
		buildingField: SC.View.design({
			layout: {centerX: 200, width:250, height:38, top: 30},
			childViews: "buildingLabel buildingField".w(),
			
			buildingLabel: SC.LabelView.design({
				layout: {left:0, width: 100, height:38, centerY: 0},
				value: "Building:"
			}),
			
			buildingField: SC.SelectFieldView.design({
				layout: {left: 120, right:0, height: 38, centerY:0}
			})
		})
	})

  // TODO: Add your own code here.

});
