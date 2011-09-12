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

