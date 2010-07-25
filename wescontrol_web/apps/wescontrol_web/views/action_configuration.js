// ==========================================================================
// Project:   WescontrolWeb.ActionConfigurationView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
sc_require('views/crud_list.js');

WescontrolWeb.ActionsConfigurationView = SC.View.extend(
/** @scope WescontrolWeb.ActionConfigurationView.prototype */ {

	classNames: ["action-configuration"],
	
	childViews: "actionList actionEdit".w(),
	
	actionList: WescontrolWeb.CrudList.design({
		layout: {top: 0, bottom: 0, left: 0, width: 200},
		contentBinding: "WescontrolWeb.actionController"
	}),
	
	actionEdit: SC.View.design({
		layout: {top: 0, bottom: 0, left: 200, right: 0},
		childViews: "deviceForm".w(),
		
		deviceForm: SC.View.design({
			layout: {centerX: 0, width: 320, top: 40, bottom: 40},
			childViews: "name source promptProjection".w(),
			
			name: SC.View.design({
				layout: {left: 0, right: 0, top: 0, height: 40},
				childViews: "nameLabel nameField".w(),
				nameLabel: SC.LabelView.design({
					layout: {left:0, width: 100, height: 30, top: 0},
					value: "Name"
				}),
				
				nameField: SC.TextFieldView.design({
					layout: {left: 120, height: 30, width: 200, top: 0},
					valueBinding: "WescontrolWeb.actionSelectionController.name"
				})
			}),
			
			source: SC.View.design({
				layout: {left: 0, right: 0, top: 50, height: 40},
				childViews: "sourceLabel sourceField".w(),
				sourceLabel: SC.LabelView.design({
					layout: {left:0, width: 100, height: 30, centerY: 0},
					value: "Source"
				}),
				
				sourceField: SC.SelectFieldView.design({
					layout: {left: 120, height: 20, width: 200, centerY: 0},
					objects: function(){
						return WescontrolWeb.sourceController.map(function(x){ 
							return {name: x.get("name"), value: x.get("guid")};
						});
					}.property("WescontrolWeb.sourceController.content"),
					nameKey: "name",
					valueKey: "value",
					disableSort: true,
					emptyName: false,
					theme: 'square',
					updateValue: function(){
						if(WescontrolWeb.actionSelectionController.get('settings'))
						{
							this.set('value', WescontrolWeb.actionSelectionController
								.get('settings').source);
						}
					}.observes("WescontrolWeb.actionSelectionController.content"),
					changed: function(){
						if(WescontrolWeb.actionSelectionController.content){
							WescontrolWeb.actionSelectionController
								.content.setSource(this.value);
						}
					}.observes('value')
				})				
			}),
			promptProjection: SC.View.design({
				layout: {left: 0, right: 0, top: 100, height: 40},
				childViews: "promptLabel promptField".w(),
				promptLabel: SC.LabelView.design({
					layout: {left:0, width: 300, height: 30, centerY: 0},
					value: "Prompt Projector?"
				}),
				promptField: SC.CheckboxView.design({
					layout: {left: 240, height: 20, width: 30, centerY: 0},
					updateValue: function(){
						var settings = WescontrolWeb.actionSelectionController
							.get('settings');
						if(settings)this.set('value', settings.prompt_projector);
					}.observes("WescontrolWeb.actionSelectionController.content"),
					changed: function(){
						if(WescontrolWeb.actionSelectionController.content){
							WescontrolWeb.actionSelectionController.content
								.setPromptProjector(this.value);
						}
					}.observes('value')
				})
			})
		})
		
	})
	

});
