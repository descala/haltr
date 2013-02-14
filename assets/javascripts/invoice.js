/* Iterate over all selects of a tax and update its values */
function global_tax_changed(tax_name, tax_code) {
  $$('select.tax_'+tax_name).each(function(select_element) {
    select_element.value=tax_code;
  });
  // call tax_changed to show/hide tax comment if exempt
  tax_changed(tax_name,tax_code);
}

/* Update form when a tax becomes global or line-specific.
 * Enables/disables global tax selector and shows/hides per line ones.
 * Iterate over all selects of a tax and update its values
 */
function global_tax_check_changed(tax_name) {
  $(tax_name+'_global').disabled=$(tax_name+'_multiple').checked;
  if ($(tax_name+'_multiple').checked) {
    $(tax_name+'_title').removeClassName('hidden');
    $$('select.tax_'+tax_name).each(function(select_element) {
      select_element.removeClassName('hidden');
    });
  } else {
    global_tax_changed(tax_name,$(tax_name+'_global').value);
    $(tax_name+'_title').addClassName('hidden');
    $$('select.tax_'+tax_name).each(function(select_element) {
      select_element.addClassName('hidden');
    });
  }
}

/* Copy last line tax percent */
function copy_last_line_tax(tax_name) {
  var last_value;
  var tax_selects = $$('select.tax_'+tax_name);
  if (tax_selects.size() > 1) {
    last_value = tax_selects[tax_selects.size() - 2].value;
  } else {
    last_value = $(tax_name+'_global').value;
  }
  tax_selects.last().value = last_value;
}

/* A tax select has changed.
 * Show comment if selected value is exempt,
 * or hide it if there are no exempt selects for this tax.
 */
function tax_changed(tax_name, tax_code) {
  if (tax_code.match(/_E$/)) {
    $(tax_name+'_comment').removeClassName('hidden');
  } else {
    var hide_comment = true;
    $$('select.tax_'+tax_name).each(function(select_element) {
      if (select_element.value.match(/_E$/)) {
        hide_comment = false;
      }
    });
    if ( hide_comment ) {
      $(tax_name+'_comment').addClassName('hidden');
    }
  }
}
