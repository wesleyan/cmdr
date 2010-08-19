// ==========================================================================
// Project:   Tp5.volumeController
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

	This controller controls volume levels and mute on any device that conforms
	to the specification of having a volume property from [0,1] named "volume"
	and a binary mute property named, well, "mute".

	@extends SC.ObjectController
*/
Tp5.volumeController = SC.ObjectController.create(
/** @scope Tp5.volumeController.prototype */ {
	
	/**
		The current volume of the device, expressed in the range [0,1]
	*/
	volume: 0,
	/**
		The current mute status
	*/
	mute: NO,
	
	lastVolumeSet: 0,
	
	_timer: null,
	
	volumeToSet: null,
	
	updateLastVolumeSet: function(){
		this.set('lastVolumeSet', this.get('volume'));
	},
	
	
	/**
		Sets the volume of the device. In order to protect from the masssive
		number of changes that a continuous property like this can get from
		a UI element like a slider, it buffers changes and prevents too many
		small changes from actually being sent.
		
		@param {v} The volume, in the range [0, 1], which to set the device to
	*/
	set_volume: function(v){
		v = Math.round(v*100)/100;
		this.volumeToSet =  v;
		this.set('lastVolumeSet', v);
	},
	
	update_volume_on_device: function(){
		if(this.volumeToSet){
			Tp5.log("Updating volume to %.2f", this.volumeToSet);
			this.set_volume_on_device(this.volumeToSet);
			this.volumeToSet = null;
		}
	},
	
	/**
		This method directly sets the volume on the device, without any buffering.
		Do not use this unless you are doing some kind of buffering yourself.
		 
		@param {v} The volume, in the range [0, 1], which to set the device to
	*/
	set_volume_on_device: function(v){
		if(this.get('content'))
		{
			Tp5.log("SETTING VOLUME: %.2f%%", v);
			this.get('content').set_var("volume", v);
		}
	},
	
	/**
		This method sets the mute on the device.
		 
		@param {on} A binary value defining whether mute should be turned on or off.
	*/
	set_mute: function(on){
		if(this.get('content'))
		{
			this.get('content').set_var("mute", on);
		}
	},
	
	updateVolume: function(){
		Tp5.log("volume changed to " + this.get('content').get('states').volume);
		this.set('volume', this.get('content').get('states').volume);
	}.observes('.content.states'),
	
	updateMute: function(){
		this.set('mute', this.get('content').get('states').mute);
	}.observes('.content.states'),
	
	updateContent: function(){
		this.set('content', Tp5.roomController.get('volume'));
		if(this.get('content'))
		{
			this._timer = SC.Timer.schedule({ 
				target: this, 
				action: 'update_volume_on_device', 
				repeats: YES, 
				interval: 500 
			});
		}
	}.observes("Tp5.roomController.volume")

}) ;
