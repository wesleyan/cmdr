// ==========================================================================
// Project:   WescontrolWeb.roomController
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your Controller Here)

  @extends SC.Object
*/
WescontrolWeb.roomController = SC.ArrayController.create(
/** @scope WescontrolWeb.roomController.prototype */ {

	/*content: SC.Object.extend({
		treeItemIsExpanded: YES,
		title: "Root",
		count: 4,
		treeItemChildren: function(){
			return WescontrolWeb.store.find(WescontrolWeb.Building).map(function(building){
				return SC.Object.extend({
					title: building.get('name'),
					treeItemIsExpanded: NO,
					treeItemChildren: function(){
						return building.rooms.map(function(room){
							return SC.Object.extend({
								title: room.get('name'),
								treeItemIsExpanded: NO
							})
						})
					}.property().cacheable()
				})
			})
		}.property().cacheable()
	})*/

}) ;
