/**
 * Removes invoice line form. If line is not a new record
 * it has a hidden_field that must be set to 1 in order to
 * really delete line.
 */
function rm_line(id) {
  var div = document.getElementById("invoice_line_"+id);
  var p = div.firstElementChild;
  div.removeChild(p);
  // set hidden_field to 1 to really delete line
  var hf = document.getElementById("destroy_line_"+id);
  if (hf != null) {
    hf.setAttribute("value", "1");
  }
}
