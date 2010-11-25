function terms() {
  var sel = document.getElementById('invoice_terms');
  var due_date = document.getElementById('invoice_due_date');
  var due_date_cal = document.getElementById('due_date_cal');
  if (sel.value == "custom") {
    due_date.disabled = false; 
    due_date_cal.style.visibility = "visible";
  } else {
    due_date.disabled = true; 
    due_date_cal.style.visibility = "hidden";
  }
}
