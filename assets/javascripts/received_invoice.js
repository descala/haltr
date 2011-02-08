/*
 * Functions for received invoices view
 */

// shows form to send mail when refusing an invoice
// also hides form showed on show_accepted_form
function show_refused_form() {
  rf = document.getElementById("invoice-refuse");
  af = document.getElementById("invoice-accept");
  rf.show();
  af.hide();
}

// shows form to send mail when accepting an invoice
// also hides form showed on show_refused_form
function show_accepted_form() {
  rf = document.getElementById("invoice-refuse");
  af = document.getElementById("invoice-accept");
  rf.hide();
  af.show();
}
