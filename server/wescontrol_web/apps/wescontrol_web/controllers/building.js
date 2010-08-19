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
	contentValueKey: 'name',
	
	refreshSources: function(){
		var buildings = SC.Object.create({
			treeItemIsExpanded: YES,
			hasContentIcon: NO,
			displayName: 'Buildings',
			treeItemChildren: WescontrolWeb.store.find(WescontrolWeb.Building).map(function(building, index){
				return SC.Object.create({
					contentValueKey: 'name',
					//displayName: building.get('name'),
					name: building.get('name'),
					guid: building.get('guid'),
					treeItemIsExpanded: index === 0,
					isBuilding: YES,
					treeItemChildren: building.get('rooms').map(function(room){
						return room.mixin({
							isRoom: YES,
							contentValueKey: 'name'
							//displayName: room.get('name')//,
						//	devices: WescontrolWeb.store.find(WescontrolWeb.Device, {conditions: 'room = {roomRecord}', roomRecord: room})
						});
					})
				});
			})
		});
		
		this.set('content', buildings);
		var rooms = this.get('arrangedObjects').filterProperty("isRoom");
		if(rooms.get('length') > 0)this.selectObject(rooms.firstObject(), NO);
	},
	
	arrangedBuildings: function(){
		if(this.get('arrangedObjects'))
		{
			return this.get('arrangedObjects').filterProperty("isBuilding");
		}
		return undefined;
	}.property().cacheable()
}) ;
