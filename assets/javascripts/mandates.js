var end_date="";
$(document).on('change', 'input[name="mandate[recurrent]"]', function(e) {
  if (this.value == "true") {
    // recurrent mandate
    $('#mandate_end_date').val(end_date);
    $('#div_mandate_end_date').show();
  } else {
    end_date = $('#mandate_end_date').val();
    $('#mandate_end_date').val("");
    $('#div_mandate_end_date').hide();
  }
});
