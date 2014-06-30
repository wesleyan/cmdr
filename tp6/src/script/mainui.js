/* jshint globalstrict : false
 */
var srcEl, spinner = false;

var toggleSpinner = function(bool) {
  'use strict';
  var opts, targets, spinner;
  if (!bool) {
    $('.spinner').empty();
    spinner = false;
  }
  else if (!spinner) {
    
    opts = {
      lines: 15, // The number of lines to draw
      length: 20, // The length of each line
      width: 10, // The line thickness
      radius: 30, // The radius of the inner circle
      corners: 1, // Corner roundness (0..1)
      rotate: 90, // The rotation offset
      direction: 1, // 1: clockwise, -1: counterclockwise
      color: '#000', // #rgb or #rrggbb or array of colors
      speed: 0.5, // Rounds per second
      trail: 100, // Afterglow percentage
      shadow: false, // Whether to render a shadow
      hwaccel: false, // Whether to use hardware acceleration
      className: 'spinner', // The CSS class to assign to the spinner
      zIndex: 2e9, // The z-index (defaults to 2000000000)
      top: '50%', // Top position relative to parent
      left: '50%' // Left position relative to parent
    };
    targets = document.getElementsByClassName('spinner');
      new Spinner(opts).spin(targets[0]);
    spinner = true;
  }
}
var onDragStart = function(e) {
  'use strict';
  //console.log('drag started');
  e.originalEvent.dataTransfer.setData('text/html', this.innerHTML);
  e.originalEvent.dataTransfer.effectAllowed = 'copy';
  srcEl = this;
  this.classList.add('drag-selected');
};
var onDragOver = function(e) {
  'use strict';
  //console.log('drag over');
  if (e.preventDefault) { e.preventDefault(); }
  e.originalEvent.dataTransfer.dropEffect = 'copy';
  return false;
};
var onDragEnter = function(e) {
  'use strict';
  //console.log('drag entering');
  this.classList.add('drag-over');
};
var onDragLeave = function(e) {
  'use strict';
  //console.log('drag leaving');
  this.classList.remove('drag-over');
};
var onDrop = function(e) {
  'use strict';
  console.log('drag dropping');
  if (e.stropPropagation) { e.stopPropagation(); }
  this.innerHTML = e.originalEvent.dataTransfer.getData('text/html');
  this.classList.remove('drag-over');
  return false;
};
var onDragEnd = function(e) {
  'use strict';
  //console.log('drag ending');
  srcEl.classList.remove('drag-selected');
};
$(document).on('dragstart', '.src', onDragStart);
$(document).on('dragover', '.out-src', onDragOver);
$(document).on('dragenter', '.out-src', onDragEnter);
$(document).on('dragleave', '.out-src', onDragLeave);
$(document).on('drop', '.out-src', onDrop);
$(document).on('dragend', '.src, .out-src', onDragEnd);

/* SETS DATE */
var findMonth = function(num) {
  'use strict';
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
  'use strict';
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
  'use strict';
  return x < 10 ? '0'+x : x;
};

/* converts hours in military to tuple of hours, am/pm */
var fromMilitary = function(hours) {
  'use strict';
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
  'use strict';
  var d = new Date();

  var h = pad(d.getHours());
  var m = pad(d.getMinutes());
  var s = pad(d.getSeconds());

  var h2 = fromMilitary(h);

  var month = findMonth(d.getMonth());
  var day = d.getDate();
  var daySuff = daySuffix(day);

  //$('#clock').html(h2[0] + ':' + m + ':' + s + ' ' + h2[1]);
  $('#clock').html(h2[0] + ':' + m + ':' + s);


  $('#month').html(month + ' ');
  $('#day').html(day);
  $('#daySuffix').html(daySuff);
};

updateTime();
setInterval(updateTime, 1000);

var adjustSources = function() {
  //deal with more than 4 sources
  if (Tp.actions.length > 4) {
    console.log('More than 4 actions');
    $('.out-name').addClass('out-name-right');
    $('.sources-list').after('<div class="src-scroll col-xs-1">'+
                             '<div class="up"><i class="icon-arrow-up3 icon-5x"></i></div>'+
                             '<div class="down"><i class="icon-arrow-down3 icon-5x"></i></div>'+
                             '</div>');
    $(document).on('click', '.up', function(event) {
      $('.sources-list').removeClass('scroll-down').addClass('scroll-up');
    });
    $(document).on('click', '.down', function(event) {
      $('.sources-list').removeClass('scroll-up').addClass('scroll-down');
    });
  }
}
window.setTimeout(adjustSources, 500);
