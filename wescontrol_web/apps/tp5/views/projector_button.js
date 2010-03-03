// ==========================================================================
// Project:   Tp5.ProjectorButtonView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
Tp5.ProjectorButtonView = SC.View.extend(
/** @scope Tp5.ProjectorButtonView.prototype */ {

	classNames: ['status-button'],
	
	childViews: "stateImage".w(),
	
	buttonBehavior: SC.PUSH_BEHAVIOR,
	
	stateImage: SC.ImageView.design({
		layout: {centerX: 0, centerY: 0, width: 67, height: 62},
		value: "projector/on"
		//valueBinding: SC.Binding.transform(function(value, binding) {
		//	return "/images/projector/" + value.state.state + ".png";
		//}).from("Tp5.deviceController.devices.projector.state_vars")
	})

});