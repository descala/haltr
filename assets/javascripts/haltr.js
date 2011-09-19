/* Show/hide payment method textarea */
function payment_method_changed(obj_name) {
  if ($(obj_name+'_payment_method').value == 13) {
    $(obj_name+'_payment_method_text').removeClassName('hidden');
  } else {
    $(obj_name+'_payment_method_text').addClassName('hidden');
  }
}
