/**
 * Removes tax form. If tax is not a new record
 * it has a hidden_field that must be set to 1 in order to
 * really delete tax.
 */
function rm_tax(id) {
  var tr = $("#tax_"+id);
  tr.remove();
  // set hidden_field to 1 to really delete line
  var hf = $("#destroy_tax_"+id);
  if (hf != null) {
    hf.attr("value", "1");
  }
}

/**
 * When tax category set to exempt, shows
 * comment and hides percent text_fields
 */
function category_changed(id) {
  var sel = $("#company_taxes_attributes_" + id + "_category>option:selected").val();
  var span_percent = $("#span_percent_" + id);
  var span_comment = $("#span_comment_" + id);
  var field_percent = $("#company_taxes_attributes_" + id + "_percent");
  if ( sel == "E" ) { // Exempt
    span_percent.hide();
    span_comment.show();
    // important to avoid sending non-zero value on exempt tax
    field_percent.val(0);
  } else {
    if (sel == "Z" ) { // ZeroRated
      field_percent.val(0);
      field_percent.attr('readOnly',true);
    } else {
      field_percent.attr('readOnly',false);
    }
    span_percent.show();
    span_comment.hide();
  }
}
