// ==========================================================================
// Project:   WescontrolWeb.DeviceControlView
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
WescontrolWeb.DeviceControlView = SC.View.extend(SC.ContentDisplay, SC.StaticLayout,
/** @scope WescontrolWeb.DeviceControlView.prototype */ {
	
	classNames: ['device-control-view'],
	content: null,
	
	updateContent: function() {
		console.log("Updating");
		var childViews = [], view;
		if(!WescontrolWeb.deviceController.get('hasContent'))return;
		view = this.createChildView(
			SC.LabelView.design({
				valueBinding: "WescontrolWeb.deviceController.name",
				textAlign: SC.ALIGN_CENTER
			}).classNames('device-name'),
			{rootElementPath: [0]}
		);
		childViews.push(view);
		
		var newThis = this;
		WescontrolWeb.deviceController.get('controllable_vars').forEach(function(c_var){
			childViews.push(newThis.createChildView(SC.LabelView.design({
				value: c_var.name
			}).classNames('var-name')));
			if(c_var.kind == "boolean")
			{
				childViews.push(newThis.createChildView(SC.View.design({
					childViews: "onButton offButton".w(),
					classNames: ['device-control-button-holder'],
					layout: {width: 192, centerX: 0, top: 0, height: 30},
					onButton: SC.ButtonView.design({
						layout: {left: 0, width: 92, height:24, top: 5},
						title: "OFF",
						theme: "square",
						isSelected: !c_var.state
					}),
					offButton: SC.ButtonView.design({
						layout: {left: 100, width: 92, height:24, top: 5},
						title: "ON",
						theme: "square",
						isSelected: c_var.state
					})
				})));
			}
			else if(c_var.kind == "percentage")
			{
				childViews.push(newThis.createChildView(SC.SliderView.design({
					layout: {centerX: 0, width: 208, top: 10, height: 30},
					step: 0.01,
					value: c_var.state
				})));
			}
			else if(c_var.kind == "option")
			{
				childViews.push(newThis.createChildView(SC.SelectButtonView.design({
					objects: c_var.options,
					theme: 'square',
					layout: {centerX: 0, width: 216, top: 5, height: 35},
					value: c_var.state
				})));
			}
		});
		this.replaceAllChildren(childViews);
	}.observes('WescontrolWeb.deviceController.hasContent', "WescontrolWeb.deviceController.content")

});
