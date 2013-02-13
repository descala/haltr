function terms() {
  if ($('invoice_terms').value == "custom") {
    $('invoice_due_date').disabled = false;
    $('due_date_cal').style.display = "inline";
  } else {
    $('invoice_due_date').disabled = true;
    $('due_date_cal').style.display = "none";
  }
}
