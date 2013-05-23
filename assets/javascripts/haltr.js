/* Show/hide payment method textarea */
function payment_method_changed(obj_name) {
  if ($('#'+obj_name+'_payment_method').value == 13) {
    $('#'+obj_name+'_payment_method_text').removeClassName('hidden');
  } else {
    $('#'+obj_name+'_payment_method_text').addClassName('hidden');
  }
}

/* Load file (located in relative path on the server) via AJAX (in synchronous mode) */
function loadFile(sUrl){

  var response;

  $.ajax({
    url: sUrl,
    method: 'get',
    dataType: 'text',
    async: false
  }).done( function(html) {
    response = html;
  }).fail( function(html) {
    alert('Something went wrong loading the xslt resource...');
  });

  return response;

/* Update currency selected */

$('.button-link').bind('ajax:success', function(){
  alert("Success!");
});

}
