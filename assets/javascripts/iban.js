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
