/**
 * Removes invoice line form. If line is not a new record
 * it has a hidden_field that must be set to 1 in order to
 * really delete line.
 */
function rm_line(id) {
  $("#invoice_line_"+id).remove();
  // set hidden_field to 1 to really delete line
  var hf = $("#destroy_line_"+id);
  if (hf != null) {
    hf.val(1);
  }
}

/* Iterate over all selects of a tax and update its values */
function global_tax_changed(tax_name, tax_code) {
  $('select.tax_'+tax_name).each(function(index) {
    $('select.tax_'+tax_name).eq(index).val(tax_code);
  });
  // call tax_changed to show/hide tax comment if exempt
  tax_changed(tax_name,tax_code);
}

/* Update form when a tax becomes global or line-specific.
 * Enables/disables global tax selector and shows/hides per line ones.
 * Iterate over all selects of a tax and update its values
 */
function global_tax_check_changed(tax_name) {
  $('#'+tax_name+'_global').prop('disabled', $('#'+tax_name+'_multiple').prop('checked'));
  if ($('#'+tax_name+'_multiple').prop('checked')) {
    $('#'+tax_name+'_title').show();
    $('select.tax_'+tax_name).show();
  } else {
    global_tax_changed(tax_name,$('#'+tax_name+'_global').val());
    $('#'+tax_name+'_title').hide();
    $('select.tax_'+tax_name).hide();
  }
}

/* Copy last line tax percent */
function copy_last_line_tax(tax_name) {
  var last_value;
  var tax_selects = $('select.tax_'+tax_name);
  if (tax_selects.size() > 1) {
    last_value = $('select.tax_'+tax_name).eq(tax_selects.size() - 2).val();
  } else {
    last_value = $('#'+tax_name+'_global').val();
  }
  tax_selects.last().val(last_value);
}

/* A tax select has changed.
 * Show comment if selected value is exempt,
 * or hide it if there are no exempt selects for this tax.
 */
function tax_changed(tax_name, tax_code) {
  if (tax_code.match(/_E$/)) {
    $('#'+tax_name+'_comment').show();
  } else {
    var hide_comment = true;
    $('select.tax_'+tax_name).each(function(index) {
      if ($('select.tax_'+tax_name).eq(index).val().match(/_E$/)) {
        hide_comment = false;
      }
    });
    if ( hide_comment ) {
      $('#'+tax_name+'_comment').hide();
    }
  }
}
