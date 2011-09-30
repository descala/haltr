/* Show/hide payment method textarea */
function payment_method_changed(obj_name) {
  if ($(obj_name+'_payment_method').value == 13) {
    $(obj_name+'_payment_method_text').removeClassName('hidden');
  } else {
    $(obj_name+'_payment_method_text').addClassName('hidden');
  }
}

/* Add function to window.onload */
function addLoadEvent(func) {
  var oldonload = window.onload;
  if (typeof window.onload != 'function') {
    window.onload = func;
  } else {
    window.onload = function() {
      if (oldonload) {
        oldonload();
      }
      func();
    }
  }
}

/* Load file (located in relative path on the server) via AJAX (in synchronous mode) */
function loadFile(sUrl){

  var response;

  new Ajax.Request(sUrl,
      {
         method:'get',
         asynchronous:false,
         onSuccess: function(transport) {
             response = transport.responseText || "no response text";
         },
         onFailure: function(){ alert('Something went wrong loading the xslt resource...') }
      });
   
  return response;
}
