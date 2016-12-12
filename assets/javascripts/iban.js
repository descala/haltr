$(document).ready(function() {
  $.each($('input.iban'), function (index, value) {
    checkIban(value);
  });
  $('form.formee').on('change', 'input.iban', function (event) {
    checkIban(this);
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

function checkIban(el) {
  var span_for_result = $('#'+$(el).data('spanForResult'));
  $.ajax({
    url: $(el).data('url'),
    data: "iban="+$(el).val(),
    method: 'get',
    dataType: 'text',
    async: false
  }).done( function(html) {
    span_for_result.html(html);
  });
}
