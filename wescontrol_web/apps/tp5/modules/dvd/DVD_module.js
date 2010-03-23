// ==========================================================================
// Project:   Tp5.ActionView
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
sc_require('lib/mouse_handling');

Tp5.DVDModule = SC.View.extend(Tp5.MouseHandlingFix,
/** @scope Tp5.ActionView.prototype */ {

	classNames: ['dvd-module'],
	
	buttons: [
		'play', 'back', 'pause', 'forward', 'stop', 'previous', 'next', 'menu', 'title'
	],
	
	render: function(context, firstTime) {
		var content = this.get('content');
		
		context = context.begin('div').addClass('title').push("DVD Player").end();
		
		context = context.begin('div').addClass('controls');
		context = context.begin('div').addClass('background')
			.begin('div').addClass('wescontrol-text').push("WesController").end()
		.end();
		this.buttons.forEach(function(name){
			context = 
				context.begin('div').addClass(name).addClass("dvd-button").attr("title", name)
					.begin('div').addClass('image').end()
				.end();
		});
		context = context.begin('div').addClass('pause-circle').end();
		
		context = context.end();
		
		context = context.begin('div').addClass('five-way')
			.begin('div').addClass('right fbutton').end()
			.begin('div').addClass('down fbutton').end()
			.begin('div').addClass('left fbutton').end()
			.begin('div').addClass('up fbutton').end()
			.begin('div').addClass('center fbutton').end()
		.end();
		
		sc_super();
	},
	
	mouseClicked: function(evt){
		if(evt.target.title && evt.target.className.split(" ").some(function(x){ return x == "dvd-button"; }))
		{
			if(Tp5.roomController.get('dvdplayer'))
			{
				Tp5.roomController.get('dvdplayer').send_command("pulse_command", evt.target.title);
			}
		}
		else if(evt.target.className.split(" ").some(function(x){return x == "fbutton";}))
		{
			console.log(evt);
			//console.log(evt.target.className.split(" ").find(function(x){return x != "fbutton";}));
		}
	}

});
