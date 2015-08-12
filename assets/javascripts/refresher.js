$(document).ready(function() {

  var state = 'sending';
  var i = 0;

  $('div.flash.notice').append('<img src ="/images/loading.gif" style="margin-left: 15px;">')

  var interval = setInterval(function() {
    i++;
    $.getJSON(window.location.pathname, function(data) {
      state = data.invoice.state;
    });
    if ( state != 'sending' || i > 5 ) {
      clearInterval(interval);
      $('div.flash.notice img').remove();
      if ( state != 'sending' ) {
        location.reload(true);
      }
    }
  }, 5000);


});
