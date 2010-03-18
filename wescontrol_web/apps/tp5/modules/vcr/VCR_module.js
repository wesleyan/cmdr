// ==========================================================================
// Project:   Tp5.VCRModule
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
sc_require('lib/mouse_handling');

Tp5.VCRModule = SC.View.extend(Tp5.MouseHandlingFix,
/** @scope Tp5.ActionView.prototype */ {

	classNames: ['vcr-module'],
	
	buttons: [
		'play', 'back', 'pause', 'forward', 'stop'
	],
	
	render: function(context, firstTime) {
		var content = this.get('content');
		
		context = context.begin('div').addClass('title').push("VCR Player").end();
		
		context = context.begin('div').addClass('controls');
		context = context.begin('div').addClass('background')
			.begin('div').addClass('wescontrol-text').push("WesController").end()
		.end();
		this.buttons.forEach(function(name){
			context = 
				context.begin('div').addClass(name).addClass("vcr-button").attr("title", name)
					.begin('div').addClass('image').end()
				.end();
		});
		context = context.begin('div').addClass('pause-circle').end();
		context = context.end();
		
		sc_super();
	},
	
	mouseClicked: function(evt){
		if(evt.target.title && evt.target.className.split(" ").some(function(x){ return x == "vcr-button"; }))
		{
			if(Tp5.roomController.get('dvdplayer'))
			{
				Tp5.roomController.get('dvdplayer').send_command("pulse_command", evt.target.title);
			}
		}
	}

});
