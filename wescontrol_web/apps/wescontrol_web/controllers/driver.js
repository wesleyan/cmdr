// ==========================================================================
// Project:   WescontrolWeb.driverController
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document Your Controller Here)

  @extends SC.Object
*/
WescontrolWeb.driverController = SC.TreeController.create(
/** @scope WescontrolWeb.driverController.prototype */ {
	
	currentType: null,
	typeHash: {},

	refreshSources: function(){
		var type_hash = {};
		var type_array = []; //this is stupid, but it's JS's fault
		WescontrolWeb.store.find(WescontrolWeb.Driver).forEach(function(driver, index){
			if(!type_hash[driver.get('type')])
			{
				type_hash[driver.get('type')] = [];
				type_array.pushObject(driver.get('type'));
			}
			type_hash[driver.get('type')].pushObject(driver);
		});
		this.set('typeHash', type_hash);
		var types = SC.Object.create({
			treeItemIsExpanded: YES,
			hasContentIcon: NO,
			isType: YES,
			treeItemChildren: type_array.map(function(type){
				return SC.Object.create({
					name: type,
					contentValueKey: 'name',
					treeItemChildren: type_hash[type].map(function(driver){
						return driver.mixin({
							isDriver: YES,
							contentValueKey: "name"
						});
					})
				});
			})
		});
		this.set('content', types);		
	},
	
	arrangedTypes: function(){
		if(this.get('arrangedObjects'))
		{
			return this.get('arrangedObjects').filterProperty("isType");
		}
		return [];
	}.property("arrangedObjects").cacheable(),
	
	arrangedDrivers: function(){
		if(this.get('content'))
		{
			return this.get('typeHash')[this.get('currentType')];
		}
		return [];
	}.property("currentType").cacheable()
	
}) ;
