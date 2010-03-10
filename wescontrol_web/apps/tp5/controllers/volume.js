// ==========================================================================
// Project:   Tp5.volumeController
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your Controller Here)

  @extends SC.Object
*/
Tp5.volumeController = SC.ObjectController.create(
/** @scope Tp5.volumeController.prototype */ {
	
	volume: 0,
	mute: NO,

	set_volume: function(v){
		if(this.get('content'))
		{
			this.get('content').set_var("volume", v);
		}
	},
	
	set_mute: function(on){
		if(this.get('content'))
		{
			this.get('content').set_var("mute", on);
		}
	},
	
	updateVolume: function(){
		console.log("Updating volume");
		this.set('volume', this.get('content').get('states').volume);
	}.observes('.content.states'),
	
	updateMute: function(){
		this.set('mute', this.get('content').get('states').mute);
	}.observes('.content.states'),
	
	updateContent: function(){
		this.set('content', Tp5.roomController.get('volume'));
		
	}.observes("Tp5.roomController.volume")

}) ;
