// ==========================================================================
// Project:   Tp5.ActionView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
Tp5.DVDModule = SC.View.extend(
/** @scope Tp5.ActionView.prototype */ {

	classNames: ['dvd-module'],
	
	buttons: [
		'play', 'rewind', 'pause', 'fastforward', 'stop', 'previous', 'next', 'menu', 'title'
	],
	
	render: function(context, firstTime) {
		var content = this.get('content');
		
		context = context.begin('div').addClass('title').push("DVD Player").end();
		
		context = context.begin('div').addClass('controls');
		context = context.begin('div').addClass('background').end();
		this.buttons.forEach(function(name){
			context = 
				context.begin('div').addClass(name).addClass("dvd-button")
					.begin('div').addClass('image').end()
				.end();
		});
		context = context.begin('div').addClass('pause-circle').end();
		context = context.end();
		
		sc_super();
	}

});
