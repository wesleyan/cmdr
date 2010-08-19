// ==========================================================================
// Project:   WescontrolWeb.roomListController
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your Controller Here)

  @extends SC.Object
*/
WescontrolWeb.roomListController = SC.ObjectController.create(
/** @scope WescontrolWeb.roomListController.prototype */ {

	contentBinding: SC.Binding.single().from("WescontrolWeb.buildingController.selection")

}) ;
