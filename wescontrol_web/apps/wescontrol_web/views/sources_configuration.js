// ==========================================================================
// Project:   WescontrolWeb.SourcesConfiguration
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your View Here)

  @extends SC.View
*/

sc_require('views/crud_list.js');

WescontrolWeb.SourcesConfigurationView = SC.View.extend(
/** @scope WescontrolWeb.SourcesConfiguration.prototype */ {

	classNames: ["sources-configuration"],
	
	childViews: "sourcesList sourcesEdit".w(),
	
	sourcesList: WescontrolWeb.CrudList.design({
		layout: {top: 0, bottom: 0, left: 0, width: 200},
		contentBinding: "WescontrolWeb.sourceController"
	}),
	
	sourcesEdit: SC.View.design({
		layout: {top: 0, bottom: 0, left: 200, right: 0},
		childViews: "deviceForm".w(),
		
		deviceForm: SC.View.design({
			layout: {left: 150, right: 150, top: 150, bottom: 150},
			
			childViews: "name projector".w(),
			
			name: SC.View.design({
				layout: {left: 0, right: 0, top: 0, height: 40},
				childViews: "nameLabel nameField".w(),
				nameLabel: SC.LabelView.design({
					layout: {left:0, width: 100, height: 30, top: 0},
					value: "Name"
				}),
				
				nameField: SC.TextFieldView.design({
					layout: {left: 120, height: 30, width: 200, top: 0},
					valueBinding: "WescontrolWeb.sourceSelectionController.name"
				})
			}),
			
			projector: SC.View.design({
				layout: {left: 0, right: 0, top: 50, height: 40},
				childViews: "inputLabel inputField".w(),
				inputLabel: SC.LabelView.design({
					layout: {left:0, width: 100, height: 30, top: 0},
					value: "Input"
				}),
				
				inputField: SC.SelectFieldView.design({
					layout: {left: 120, height: 20, width: 200, top: 0},
					objects: [{name:"RGB1"}, {name:"RGB2"}, {name:"VIDEO"}, {name:"SVIDEO"}],
					nameKey: "name",
					valueKey: "name",
					disableSort: true,
					emptyName: false,
					theme: 'square',
					updateValue: function(){
						if(WescontrolWeb.sourceSelectionController.get('input'))
						{
							this.set('value', WescontrolWeb.sourceSelectionController.get('input').projector);
						}
					}.observes("WescontrolWeb.sourceSelectionController.input")
				})				
			})
						
			
		})
		
	})
	

});
