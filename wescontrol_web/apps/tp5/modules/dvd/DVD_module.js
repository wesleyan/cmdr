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
	
	regions: [
		{
			action: 'enter',
			shape: "circle",
			center: [77, 77],
			radius: 23
		},
		{
			action: "left",
			coords: [[77,77], [23, 23], [0,77], [23, 131]]
		},
		{
			action: "right",
			coords: [[77,77], [131,23], [170,75], [131,131]]
		},
		{
			action: "up",
			coords: [[77,77], [131, 23], [77,0], [23,23]]
		},
		{
			action: "down",
			coords: [[77,77], [131, 131], [77, 170], [23, 131]]
		}
	],
	
	pointInPolygon: function(poly, point){
		var x = point[0];
		var y = point[1];
		if(poly.shape == "circle")
		{
			return Math.pow(x-poly.center[0],2) + Math.pow(y - poly.center[1],2) < Math.pow(poly.radius,2);
		}
		else
		{
			var c, i, l, j;
			poly = poly.coords;
		    for(c = false, i = -1, l = poly.length, j = l - 1; ++i < l; j = i)
			{
				var test1 = (poly[i][1] <= y && y < poly[j][1]) || (poly[j][1] <= y && y < poly[i][1]);
				var test2 = x < (poly[j][0] - poly[i][0]) * (y - poly[i][1]) / (poly[j][1] - poly[i][1]) + poly[i][0];
		        if(test1 && test2)c = !c;
			}
		    return c;
		}
	},
	
	
	render: function(context, firstTime) {
		var content = this.get('content');
		
		context = context.begin('div').addClass('title').addClass('top-margin').push("DVD Player").end();
		
		context = context.begin('div').addClass('controls');
		context = context.begin('div').addClass('background')
			.begin('div').addClass('wescontrol-text').push("Roomtroller").end()
		.end();
		this.buttons.forEach(function(name){
			context = 
				context.begin('div').addClass(name).addClass("dvd-button").attr("title", name)
					.begin('div').addClass('image').end()
				.end();
		});
		context = context.begin('div').addClass('pause-circle').end();
		
		context = context.end();
		
		context = context.begin('div').addClass('five-way').end();
		context = context.end().end().end;
		
		sc_super();
	},
	
	mouseDown: function(evt){
		if(evt.target.className.split(" ").some(function(x){return x == "five-way";}))
		{
			//unfortunately, we have to use js to inspect the coordinates of the touch in order to see
			//which button was pressed. I wish there was a better way to do this, but there appears not
			//to be.			
			var x = evt.originalEvent.offsetX;
			var y = evt.originalEvent.offsetY;
			for(var i = 0; i < this.regions.get('length'); i++)
			{
				if(this.pointInPolygon(this.regions.objectAt(i), [x,y]))
				{
					SC.$('.five-way')[0].className = "five-way " + this.regions.objectAt(i).action;
					break;
				}
			}
		}
	},
	
	mouseClicked: function(evt){
		var action = null;
		if(evt.target.title && evt.target.className.split(" ").some(function(x){ return x == "dvd-button"; }))
		{
			action = evt.target.title;
		}
		else if(SC.$('.five-way')[0].className.split(" ").some(function(x){ return x != "five-way";}))
		{
			action = SC.$('.five-way')[0].className.split(" ").find(function(x){ return x != "five-way";});
			SC.$('.five-way')[0].className = "five-way";
		}
		if(Tp5.roomController.get('dvdplayer') && action)
		{
			Tp5.roomController.get('dvdplayer').send_command("pulse_command", evt.target.title);
		}
	}

});
