slinky_require('../../lib/module.coffee')

BlurayModule = Tp.Module.extend
  name: "bluray"

  buttons: ['play', 'back', 'pause', 'forward', 'stop', 'eject', 'previous', 'next', 'menu', 'title']

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
  ]

  render: () ->
    ($.tmpl @template_name, {buttons: @buttons})

  module_loaded: ->
    $('.five-way').mousedown (e) =>
      x = e.originalEvent.offsetX
      y = e.originalEvent.offsetY
      for region in @regions
        if @point_in_polygon region, [x, y]
          $('.five-way').attr('class', 'five-way ' + region.action)
          break

    $('.five-way').click (e) =>
      action = $('.five-way').attr('class').split(' ')[1]
      $('.five-way').attr('class', 'five-way')
      @do_action action

    $('.dvd-button').click (e) =>
      @do_action e.target.title

  do_action: (action) ->
    Tp.devices.blurayplayer?.command action

  point_in_polygon: `function (poly, point){
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
  }`


Tp.modules.bluray = new BlurayModule()
