// ==========================================================================
// Project:   WescontrolWeb.buildingController
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your Controller Here)

  @extends SC.Object
*/
WescontrolWeb.buildingController = SC.TreeController.create(
/** @scope WescontrolWeb.roomController.prototype */ {
	
	treeItemIsGrouped: YES,
	content: null,
	
	refreshSources: function(){
		var buildings = SC.Object.create({
			treeItemIsExpanded: YES,
			hasContentIcon: NO,
			displayName: 'Buildings',
			treeItemChildren: WescontrolWeb.store.find(WescontrolWeb.Building).map(function(building){
				return SC.Object.create({
					contentValueKey: 'displayName',
					displayName: building.get('name'),
					treeItemChildren: building.get('rooms').map(function(room){
						return SC.Object.create({
							displayName: room.get('name'),
							devices: room.get('devices')
						});
					})
				});
			})
		});
		
		this.set('content', buildings);
		//this.set('selection', SC.SelectionSet.create);
	}
}) ;
