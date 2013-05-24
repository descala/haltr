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
}


function terms(){
  if ($('#invoice_terms').val() == "custom") {
    $('#invoice_due_date').prop('disabled', false);
    $('#due_date_cal').show();
  } else {
    $('#invoice_due_date').prop('disabled', true);
    $('#due_date_cal').hide();
  }
}

$(document).ready(function() {

  /* Bind update payment stuff in an issued invoice form */
  $('select#invoice_client_id').bind('ajax:success', function(evt, data, status, xhr){
    $('#payment_stuff').html(xhr.responseText);
    terms();
  })

  $(document).on('change', '#invoice_terms', function(e) {
    terms();
  });

  $(document).on('change', '#invoice_payment_method, #client_payment_method', function(e) {
    if ($(this).val()==13) {
      $('#payment_other').show();
    } else {
      $('#payment_other').hide();
    }
  });

});

