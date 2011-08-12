/**
 * Removes tax form. If tax is not a new record
 * it has a hidden_field that must be set to 1 in order to
 * really delete tax.
 */
function rm_tax(id) {
  var div = document.getElementById("tax_"+id);
  var p = div.firstElementChild;
  div.removeChild(p);
  // set hidden_field to 1 to really delete line
  var hf = document.getElementById("destroy_tax_"+id);
  if (hf != null) {
    hf.setAttribute("value", "1");
  }
}
