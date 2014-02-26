$(document).ready(function() {
  $('form.formee').on('change', 'input.iban', function (event) {
    var span_for_result = $('#'+$(this).data('spanForResult'));
    $.ajax({
      url: $(this).data('url'),
      data: "iban="+$(this).val(),
      method: 'get',
      dataType: 'text',
      async: false
    }).done( function(html) {
      span_for_result.html(html);
    });
  });
});

$(document).ready(function() {
  $('#ccc2iban').on('click', function (event) {
    var ccc=prompt('Enter spanish CCC');
    var for_result = $('#client_iban');
    $.ajax({
      url: $(this).data('url'),
      data: "ccc="+ccc,
      method: 'get',
      dataType: 'text',
      async: false
    }).done( function(iban) {
      for_result.val(iban);
    });
    return false;

  });
});
