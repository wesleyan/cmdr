var SOURCE = Object.freeze({ PC: 'pc', MAC: 'mac', HDMI: 'hdmi', VGA: 'vga', DVD: 'dvd', BLURAY: 'bluray' });
var OUTPUT = Object.freeze({ PROJECTOR: 'projector', TELEVISION: 'television' });

/* DYNAMICALLY CREATE PROJECTORS AND SOURCES */
//var sources = { 1: SOURCE.MAC };
//var sources = { 1: SOURCE.MAC, 2: SOURCE.PC };
//var sources = { 1: SOURCE.MAC, 2: SOURCE.PC, 3: SOURCE.HDMI };
//var sources = { 1: SOURCE.MAC, 2: SOURCE.PC, 3: SOURCE.HDMI, 4: SOURCE.VGA };
var sources = { 1: SOURCE.MAC, 2: SOURCE.PC, 3: SOURCE.HDMI, 4: SOURCE.VGA, 5: SOURCE.DVD };
//var sources = { 1: SOURCE.MAC, 2: SOURCE.PC, 3: SOURCE.HDMI, 4: SOURCE.VGA, 5: SOURCE.DVD, 6: SOURCE.MAC };
//var sources = { 1: SOURCE.MAC, 2: SOURCE.PC, 3: SOURCE.HDMI, 4: SOURCE.VGA, 5: SOURCE.DVD,
//                6: SOURCE.MAC, 7: SOURCE.PC, 8: SOURCE.HDMI, 9: SOURCE.VGA, 10: SOURCE.DVD};
var outs = { 1: { name: 'projector', type: OUTPUT.PROJECTOR, source: undefined, on: false, vm: false} };
//var outs = { 1: { name: '0123456789', type: OUTPUT.PROJECTOR, source: undefined, on: false, vm: false },
//             2: { name: 'east', type: OUTPUT.PROJECTOR, source: undefined, on: false, vm: false } };

//var outs = { 1: { name: '0123456789', type: OUTPUT.PROJECTOR, source: undefined, on: false, vm: false },
//             2: { name: 'east', type: OUTPUT.PROJECTOR, source: undefined, on: false, vm: false },
//             3: { name: 'north', type: OUTPUT.TELEVISION, source: undefined, on: false, vm: false },
//             4: { name: 'north', type: OUTPUT.TELEVISION, source: undefined, on: false, vm: false } };

var state = { active: 1};

var getSourceIcon = function(s, x) {
  switch(s) {
    case SOURCE.HDMI:
      return 'cf icon-hdmi cf-' + x + 'x';
    case SOURCE.VGA:
      return 'cf icon-vga cf-' + x + 'x';
    case SOURCE.MAC:
      return 'fa fa-apple fa-' + x + 'x';
    case SOURCE.PC:
      return 'fa fa-windows fa-' + x + 'x';
    case SOURCE.DVD:
      return 'cf icon-dvd cf-' + x + 'x';
    default:
      return 'cf icon-cmdr cf-' + x + 'x';
  }
};
var getOutputIcon = function(o) {
  switch(o) {
    case OUTPUT.PROJECTOR:
      return 'fa fa-video-camera';
    case OUTPUT.TELEVISION:
      return 'fa fa-desktop';
    default:
      return 'fa fa-video-camera';
  }
};

var addOutputs = function(outputs) {
  var navHtml = '';
  var octHtml = '<div class="out-info">'+
                '</div>'+
                '<div class="out-ctrl">'+
                  '<div class="pwr-btn">'+
                    '<label>'+
                      '<i class="fa fa-power-off fa-3x"></i>'+
                    '</label>'+
                  '</div>'+
                  '<div class="vm-btn">'+
                    '<label>'+
                      '<span class="vm-txt">VIDEO MUTE</span>'+
                    '</label>'+
                  '</div>'+
                '</div>';
  $('#out-group').prepend('<div id="nav-left" class="col-xs-1">'+
                            '<i class="fa fa-chevron-left fa-3x"></i>'+
                          '</div>'
                ).append('<div id="nav-right" class="col-xs-1">'+
                            '<i class="fa fa-chevron-right fa-3x"></i>'+
                          '</div>');
  for (var o in outputs) {
    if (outputs.hasOwnProperty(o)) {
      console.log(o);
      $('#o-'+o).prepend('<div class="nav-item" data-tab="'+o+'">'+
                           '<i class="'+getOutputIcon(outputs[o].type)+'"></i>'+
                           '<span>'+outputs[o].name.substring(0,9)+'</span>'+
                         '</div>'
               ).append(octHtml);
    }
  }
  $('#o-1 > .nav-item').addClass('active');
};

//addOutputs(outs);

var addSources = function(sources) {
  var html = '';
  var n = Object.keys(sources).length;
  var shape = n < 7 ? '.f-' : '.d-';

  $('.out-info').html('<div class="transforms">'+
                        '<div class="cube c-6">'+
                          '<div class="face f-1">'+
                            '<i class="fa-7x"></i>'+
                          '</div>'+
                          '<div class="face f-2">'+
                            '<i class="fa-7x"></i>'+
                          '</div>'+
                          '<div class="face f-3">'+
                            '<i class="fa-7x"></i>'+
                          '</div>'+
                          '<div class="face f-4">'+
                            '<i class="fa-7x"></i>'+
                          '</div>'+
                          '<div class="face f-5">'+
                            '<i class="fa-7x"></i>'+
                          '</div>'+
                          '<div class="face f-6">'+
                            '<i class="fa-7x"></i>'+
                          '</div>'+
                        '</div>'+
                      '</div>');

  $('#src-group').append(
                  '<div id="src-stage"><div id="src-slide"></div></div>'
                ).prepend(
                  '<div id="src-left"><i class="fa fa-chevron-left fa-3x">'
                ).append(
                  '<div id="src-right"><i class="fa fa-chevron-right fa-3x">'
                ).addClass(
                  'overflow-hidden'
                );

  if (n < 6) {
    console.log('no source slide');
    for (var s in sources) {
      if (sources.hasOwnProperty(s)) {
        html += '<div class="src" id="src-'+sources[s]+'">'+
                  '<input type="radio" name="source" data-face="'+s+'">'+
                  '<label>'+
                    '<div><i class="'+getSourceIcon(sources[s], 2)+'"></i></div>'+
                    '<div>'+sources[s]+'</div>'+
                  '</label>'+
                '</div>';
        console.log(shape+s+' > i');
        console.log($(shape+s+' > i'));
        console.log(getSourceIcon(sources[s], 7));
        console.log(sources[s]);
        $(shape+s+' > i').addClass(getSourceIcon(sources[s], 7));
      }
    }
    console.log(html);
    $('#src-group').html(html);
  }
  else {
    console.log('source slide');
    for (var s in sources) {
      if (sources.hasOwnProperty(s)) {
        html += '<div class="src" id="src-'+sources[s]+'" style="-webkit-transform: translateX('+(s-1)*100+'px)">'+
                  '<input type="radio" name="source" data-face="'+s+'">'+
                  '<label>'+
                    '<div><i class="'+getSourceIcon(sources[s], 2)+'"></i></div>'+
                    '<div>'+sources[s]+'</div>'+
                  '</label>'+
                '</div>';
        $(shape+s+' > i').addClass(getSourceIcon(sources[s], 7));
      } 
    }
    $('#src-slide').append(html).addClass('src-slide-left');
  }

};

//addSources(sources);

/* SLIDE LISTENER */
$(document).on('click', '#src-left', function() {
  var s = $('#src-slide').addClass('src-slide-left').removeClass('src-slide-right');
});
$(document).on('click', '#src-right', function() {
  var s = $('#src-slide').addClass('src-slide-right').removeClass('src-slide-left');
});

/* POWER BUTTON LISTENER */
$(document).on('click', '.pwr-btn > label', function() {
 // var current = outs[state.active];
 // var that = this;
 // if (!$(this).hasClass('pwr-on')) {
 //   this.disabled = true;
 //   var blink = setInterval(warming, 500);
 //   window.setTimeout(clearInterval, 5000, blink);
 //   window.setTimeout(powerOn, 5000, that);
 //   current.on = true;
 // }
 // else {
 //   $(this).removeClass('pwr-on');
 //   $('#o-'+state.active+' .cube').addClass('c-top');
 //   current.on = false;
 // }
});
var warming = function() {
 // console.log('warming on o-'+state.active);
 // var label = $('#o-'+state.active+' .pwr-btn > label');
 // if (label.hasClass('warming')) {
 //   label.removeClass('warming');
 // }
 // else {
 //   label.addClass('warming');
 // }
};
var powerOn = function(that) {
 // $(that).removeClass('warming');
 // $(that).addClass('pwr-on');
 // $('#o-'+state.active+' .cube').removeClass('c-top');
 // that.disabled = false;
};
/* VIDEO MUTE LISTENER */
$(document).on('click','.vm-btn > label', function() {
 // var current = state.active;
 // if (!$(this).hasClass('vm-on')) {
 //   $(this).addClass('vm-on');
 //   $('.cube').addClass('cube-vm');
 //   outs[current].vm = true;
 // }
 // else {
 //   $(this).removeClass('vm-on');
 //   $('.cube').removeClass('cube-vm');
 //   outs[current].vm = false;
 // }
});

/* TAB NAVIGATION */
$(document).on('click', '#nav-left', function() {
  var active = $('.active').data().tab;
  if (active - 1 > 0) {
    state.active = active - 1;
    $('.active').removeClass('active');
    $('#octagon div:nth-child('+(active-1)+') > .nav-item').addClass('active');
    $('#octagon').removeClass('p-out-' + active).addClass('p-out-' + (active - 1));

    var nextSource = outs[state.active].source;
    if (nextSource) {
      $('#src-'+nextSource).click();
    }
    else {
      $('.src > input').prop('checked', false);
    }
  }
});
$(document).on('click', '#nav-right', function() {
  var active = $('.active').data().tab;
  if (active < Object.keys(outs).length) {
    state.active = active + 1;
    $('.active').removeClass('active');
    console.log(active);
    $('#octagon div:nth-child('+(active+1)+') > .nav-item').addClass('active');
    $('#octagon').removeClass('p-out-' + active).addClass('p-out-' + (active + 1));

    var nextSource = outs[state.active].source;
    if (nextSource) {
      $('#src-'+nextSource).click();
    }
    else {
      $('.src > input').prop('checked', false);
    }
  }
});

/* SOURCE SELECTION LISTENER */
$(document).on('click', '.src', function() {
//  var cur = state.active;
//  var s = $(this).children('label').children(':last-child').html();
//  console.log('switching '+cur+' to '+s);
//  $('#src-' + s + ' input').prop('checked', true);
//  var newClass = $(this).children('input').data('face');
//  console.log('new Class: '+newClass);
//  $('#o-'+cur+' .cube').removeClass('c-1 c-2 c-3 c-4 c-5 c-6').addClass('c-'+newClass);
//  outs[cur].source = s;
});


/* Returns correct class */
var getMatrixClass = function(s) {
  switch(s) {
    case 'mac':
      return 'c-front';
    case 'pc':
      return 'c-bottom';
    case 'vga':
      return 'c-back';
    case 'dvd':
      return 'c-right';
    case 'hdmi':
      return 'c-left';
    case 'bluray':
      return 'c-top';
  }
};


/* Initial configuration */
//   /* vga */$('.cube').addClass('c-6');
//$('.out-nav-item')[0].click();


/* Prevent dragging of images */
$('img').on('dragstart', function(event) {
  event.preventDefault();
}); 



/* SETS DATE */
var findMonth = function(num) {
  switch (num) {
    case 0 :
      return 'Jan';
    case 1 :
      return 'Feb';
    case 2 :
      return 'Mar';
    case 3 :
      return 'Apr';
    case 4 :
      return 'May';
    case 5 :
      return 'Jun';
    case 6 :
      return 'Jul';
    case 7 :
      return 'Aug';
    case 8 :
      return 'Sep';
    case 9 :
      return 'Oct';
    case 10 :
      return 'Nov';
    case 11 :
      return 'Dec';
  }
};
var daySuffix = function(num) {
  switch (num) {
    case (num === 1 || num === 21 || num === 31) : 
      return 'st';
    case (num === 2 || num === 22) : 
      return 'nd';
    case (num === 3 || num === 23) :
      return 'rd';
    default :
      return 'th';
  }
};

/* Pads single digits with zeros */
var pad = function(x) {
  return x < 10 ? '0'+x : x;
};

/* converts hours in military to tuple of hours, am/pm */
var fromMilitary = function(hours) {
  if (hours >= 12) {
    hours = hours - 12;
    hours = (hours === 0) ? 12 : hours;
    return [hours, 'pm'];
  }
  else {
    return [hours, 'am'];
  }
};

/* updates the clock */
var updateTime = function() {
  var d = new Date();

  var h = pad(d.getHours());
  var m = pad(d.getMinutes());
  var s = pad(d.getSeconds());

  var h2 = fromMilitary(h);

  var month = findMonth(d.getMonth());
  var day = d.getDate();
  var daySuff = daySuffix(day);

  $('#clock').html(h2[0] + ':' + m + ':' + s + ' ' + h2[1]);


  $('#month').html(month + ' ');
  $('#day').html(day);
  $('#daySuffix').html(daySuff);
};
/* calls updateTime every second */
updateTime();
setInterval(updateTime, 1000);

/* VOLUME KNOB MUTE CONTROL */
$(document).on('click','#vol-mute', function() {
 // if (!$(this).hasClass('vol-muted-m')) {
 //   $(this).addClass('vol-muted-m');
 //   $('#vol-switches > label').each(function() {
 //     $(this).children('div').children('div').addClass('vol-muted');
 //     if ($(this).children('div').children('div').hasClass('vol-checked')) {
 //       $(this).children('div').children('div').addClass('vol-checked-muted');
 //     }
 //   });
 //   $('input[name="switch"]').attr('disabled',true);
 // }
 // else {
 //   $(this).removeClass('vol-muted-m');
 //   $('#vol-switches > label').each(function() {
 //     $(this).children('div').children('div').removeClass('vol-muted');
 //     if ($(this).children('div').children('div').hasClass('vol-checked')) {
 //       $(this).children('div').children('div').removeClass('vol-checked-muted');
 //     }
 //   });
 //   $('input[name="switch"]').attr('disabled',false);
 // }
});
  /* VOLUME KNOB LEVEL CONTROL */
$(document).on('click', '.vol-c', function() {
  var label = $(this).parent().parent();
  if (!$('#vol-mute').hasClass('vol-muted-m')) {
    label.nextAll('label').each(function() {
      $(this).children('div').children('div').removeClass('vol-checked');
    });
    label.prevAll('label').not('#switch-m-l').each(function() {
      $(this).children('div').children('div').addClass('vol-checked');
    });
    $(this).addClass('vol-checked');
  }
});
