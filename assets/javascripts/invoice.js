/**
 * Removes invoice line form. If line is not a new record
 * it has a hidden_field that must be set to 1 in order to
 * really delete line.
 */
function rm_line(id) {
  $("invoice_line_"+id).remove();
  // set hidden_field to 1 to really delete line
  var hf = $("destroy_line_"+id);
  if (hf != null) {
    hf.value = 1;
  }
}

/* Iterate over all selects of a tax and update its values */
function tax_changed(tax_name, tax_percent) {
  $$('select.tax_'+tax_name).each(function(tax_select) {
    tax_select.value=tax_percent;
  });
}

/* Update form when a tax becomes global or line-specific.
 * Enables/disables global tax selector and shows/hides per line ones.
 * Iterate over all selects of a tax and update its values
 */
function global_tax_check_changed(name) {
  $(name+'_global').disabled=$(name+'_multiple').checked;
  if ($(name+'_multiple').checked) {
    $(name+'_title').removeClassName('hidden');
    $$('select.tax_'+name).each(function(tax_select) {
      tax_select.removeClassName('hidden');
    });
  } else {
    tax_changed(name,$(name+'_global').value);
    $(name+'_title').addClassName('hidden');
    $$('select.tax_'+name).each(function(tax_select) {
      tax_select.addClassName('hidden');
    });
  }
}

/* Copy last line tax percent */
function copy_last_line_tax(tax_name) {
  tax_selects = $$('select.tax_'+tax_name);
  if (tax_selects.size > 1) {
    last_value = tax_selects[tax_selects.size() - 2].value;
  } else {
    last_value = $(tax_name+'_global').value;
  }
  tax_selects.last().value = last_value;
}

