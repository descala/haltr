/* Load file (located in relative path on the server) via AJAX (in synchronous mode) */
function loadFile(sUrl){

  var response;

  $.ajax({
    url: sUrl,
    method: 'get',
    dataType: 'text',
    async: false
  }).done( function(html) {
    response = html;
  }).fail( function(html) {
    alert('Something went wrong loading the xslt resource...');
  });

  return response;
}


function terms(){
  if ($('#invoice_terms').val() == "custom") {
    $('#invoice_due_date').prop('disabled', false);
    $('#due_date_cal').show();
  } else {
    $('#invoice_due_date').prop('disabled', true);
    $('#due_date_cal').hide();
  }
}

$(document).ready(function() {

  /* Bind update payment stuff in an issued invoice form */
  $('select#invoice_client_id').bind('ajax:success', function(evt, data, status, xhr){
    $('#payment_stuff').html(xhr.responseText);
    terms();
    $('span#invoice_format').html($('select#invoice_client_id option:selected').data('channel'));
    if ( /ubl/i.test($('select#invoice_client_id option:selected').data('format')) ) {
      //TODO show UBL stuff tab
    } else {
      //TODO hide UBL stuff tab
    }
  })

  /* on load, simulate a client change to call above function */
  /* but only when creating new invoice, to avoid undesired changes */
  if (window.location.href.indexOf("/new") > -1) {
    $('select#invoice_client_id').change();
  }

  // external company form
  $(document).on('click', 'input.visible_field', function(e) {
    if (!this.checked) {
      $('#'+$(this).attr('id').replace('visible','required')).prop('checked', false);
    }
  });
  $(document).on('click', 'input.required_field', function(e) {
    if (this.checked) {
      $('#'+$(this).attr('id').replace('required','visible')).prop('checked', true);
    }
  });

  $(document).on('click', 'span.select_to_edit', function(e) {
    var field=$(this).data('field');
    $("select#invoice_"+field).toggle();
    $("select#invoice_"+field).prop('disabled', !$("select#invoice_"+field).prop('disabled'));
    $("input#invoice_"+field).toggle();
    $("input#invoice_"+field).prop('disabled', !$("input#invoice_"+field).prop('disabled'));
    $(this).toggleClass('icon-fa-pencil fa-ban');
    var tmp=$(this).data('text');
    $(this).data('text', $(this).text());
    $(this).text(tmp);
  });

  $(document).on('change', '#invoice_terms', function(e) {
    terms();
  });

  $(document).on('change', '#invoice_payment_method, #client_payment_method', function(e) {
    if ($(this).val()==13) {
      $('#payment_other').show();
    } else {
      $('#payment_other').hide();
    }
  });

  /* Called after an invoice line is added by cocoon
   *  taxNames exemple = "tax1 tax2 tax3"
   */
  $('#invoice_lines').bind('cocoon:after-insert', function(e, added_line) {
    var taxes = $('#invoice_lines').data('taxNames');
    var taxes_array = taxes.split(" ");
    for (var i = 0, length = taxes_array.length; i < length; i++) {
      global_tax_check_changed(taxes_array[i]);
      copy_last_line_tax(taxes_array[i]);
    };
  });

  $(document).on('change', '.global_tax', function(e) {
    tax_name = $(this).data('taxName');
    tax_code = $(this).val();
    global_tax_changed(tax_name,tax_code);
  });

  $(document).on('change', '.global_tax_check', function(e) {
    tax_name = $(this).data('taxName');
    global_tax_check_changed(tax_name);
  });

  $(document).on('change', '#client_taxcode', function(e) {
    client_taxcode_changed();
  });

  if ( $('#client_taxcode')[0] ) { client_taxcode_changed() };

  $(document).on('click', 'a.icon-haltr-send.disabled', function(e) {
    $('div.flash.error').remove();
    $(this).parents('div').first().append(
      $("<div></div>").addClass('flash').addClass('error').html($(this).attr('tiptitle'))
    );
  });

  $(document).on('mousemove', 'div.audited li', function(e) {
    $('div.audited-changes').css({
      "left":  e.pageX + 15,
      "top":   e.pageY - $('div#audited_changes_'+$(this).data('id')).height()
    });
  });

  $(document).on('mouseenter', 'div.audited li', function(e) {
    // move element to <body> so absolute positioning works
    var elem = $('div#audited_changes_'+$(this).data('id')).detach();
    $('body').append(elem);
    elem.show();
  });

  $(document).on('mouseleave', 'div.audited li', function(e) {
    $('div#audited_changes_'+$(this).data('id')).hide();
  });

  $('#denied_show_hide').on('click', function(e) {
    $('#denied_requests').toggle();
  });

  $(document).on('change', 'select#invoice_currency', function(e) {
    if ($("select#invoice_currency option:selected" ).val() == 'EUR') {
      $('div#exchange_fields').hide();
    } else {
      $('div#exchange_fields').show();
    }
  });

  $(document).keyup(function(e) {
    if (e.keyCode === 27) {
      $('#new_client_wrapper').hide();
      $('.mail_box').parent().hide();
    }
  });

  $(document).on('change', 'select#sel-results', function(e) {
    window.location.search = setUrlParameter(window.location.search, 'per_page', $(this).val());
  });

  // reset invoices filter
  $('input#reset').click(function() {
    $(this.form.elements).not(':button, :submit, :reset, :hidden')
      .val('')
      .removeAttr('checked')
      .removeAttr('selected');
    return false;
  });

  // new invoice "continue" button
  $('input#invoice-continue').click(function() {
    $('.nav li a[href^="#invoice-content"]').click();
    $('div#invoice-continue-show').removeClass('hide');
    return false;
  });

  // functions-clients.js
  if ( $(".table .show-audits").length > 0 ) {
    // prevent duplicated click bind #6510
    $( ".table a.show-audits" ).off('click');
    $( ".table a.show-audits" ).click(function() {
      if ( $( this ).find("i").hasClass( "fa-plus-square" ) ) {
        $( this ).find("i").removeClass( "fa-plus-square" );
        $( this ).find("i").addClass( "fa-minus-square" );
        $('#audited_'+$(this).data('id')).toggle();
        return false;
      } else {
        $( this ).find("i").removeClass( "fa-minus-square" );
        $( this ).find("i").addClass( "fa-plus-square" );
        $('#audited_'+$(this).data('id')).toggle();
        return false;
      }

    });
  }
  if ( $(".titularAccFilters").length > 0 ) {
    $(".titularAccFilters").click(function() {
      if ( $( this ).hasClass( "icon-fa-right-angle-down" ) ) {
        $( this ).removeClass( "icon-fa-right-angle-down" );
        $( this ).addClass( "icon-fa-right-angle-up" );
      } else {
        $( this ).removeClass( "icon-fa-right-angle-up" );
        $( this ).addClass( "icon-fa-right-angle-down" );
      }

    });
  }
  if ( $(".table-lines .plus-options").length > 0 ) {
    $(".table-lines .plus-options a").click(function() {
      if ( $( this ).hasClass( "icon-fa-right-angle-down" ) ) {
        $( this ).next().slideDown();
        $( this ).removeClass( "icon-fa-right-angle-down" );
        $( this ).addClass( "icon-fa-right-angle-up" );
      } else {
        $( this ).next().slideUp();
        $( this ).removeClass( "icon-fa-right-angle-up" );
        $( this ).addClass( "icon-fa-right-angle-down" );
      }
    });
  }
  $('#invoice_lines').on('cocoon:after-insert', function(e, insertedItem) {
    insertedItem.find('.plus-options a').click(function() {
      if ( $( this ).hasClass( "icon-fa-right-angle-down" ) ) {
        $( this ).next().slideDown();
        $( this ).removeClass( "icon-fa-right-angle-down" );
        $( this ).addClass( "icon-fa-right-angle-up" );
      } else {
        $( this ).next().slideUp();
        $( this ).removeClass( "icon-fa-right-angle-up" );
        $( this ).addClass( "icon-fa-right-angle-down" );
      }
    });
  });

  $('.modal.fade').on('show.bs.modal', function (e) {  /* evitamos movimientos con los modal */
    $("body").addClass( "no-pad-right" );
  })
  $(".clickable-row > tr").click(function() {
    window.location = $(this).data("href");
  });
  if ( $(".table-show").length > 0 ) {
    $(".table-show > tbody > tr").hover(
        function() { $( this ).find(".fa").toggle(); },
        function() { $( this ).find(".fa").toggle(); });
  }
  // load invoice form tab matching url anchor
  if ( $('div#invoice-content').length > 0 ) {
    var invoice_tab;
    var stripped_url = document.location.toString().split("#");
    if (stripped_url.length > 1) {
      invoice_tab = stripped_url[1];
      $('a[href="#'+invoice_tab+'"]').click();
    }
  }

});


function client_taxcode_changed() {
  var taxcode = $('#client_taxcode').val();
  // do nothing if taxcode is empty
  if (taxcode != "") {
    $.ajax({
      url: $('#client_taxcode').data('checkCifUrl'),
      data: 'value=' + taxcode + "&context=" + $('#client_taxcode').data('context'),
      dataType: "html"
    }).done(function( html ) {
      $("#cif_info").html(html);
    })
  }
}

/* Iterate over all selects of a tax and update its values */
function global_tax_changed(tax_name, tax_code) {
  $('select.tax_'+tax_name).each(function(index) {
    $('select.tax_'+tax_name).eq(index).val(tax_code);
  });
  // call tax_changed to show/hide tax comment if exempt
  tax_changed(tax_name,tax_code);
}

/* Update form when a tax becomes global or line-specific.
 * Enables/disables global tax selector and shows/hides per line ones.
 * Iterate over all selects of a tax and update its values
 */
function global_tax_check_changed(tax_name) {
  $('#'+tax_name+'_global').prop('disabled', $('#'+tax_name+'_multiple').prop('checked'));
  if ($('#'+tax_name+'_multiple').prop('checked')) {
    $('.'+tax_name+'_title').show();
    $('td.tax_'+tax_name).show();
  } else {
    global_tax_changed(tax_name,$('#'+tax_name+'_global').val());
    $('.'+tax_name+'_title').hide();
    $('td.tax_'+tax_name).hide();
  }
}

/* Copy last line tax percent */
function copy_last_line_tax(tax_name) {
  var last_value;
  var tax_selects = $('select.tax_'+tax_name);
  if (tax_selects.size() > 1) {
    last_value = $('select.tax_'+tax_name).eq(tax_selects.size() - 2).val();
  } else {
    last_value = $('#'+tax_name+'_global').val();
  }
  tax_selects.last().val(last_value);
}

/* A tax select has changed.
 * Show comment if selected value is exempt,
 * or hide it if there are no exempt selects for this tax.
 */
function tax_changed(tax_name, tax_code) {
  if (tax_code.match(/(_E|_NS)$/)) {
    $('.'+tax_name+'_comment').show();
  } else {
    var hide_comment = true;
    $('select.tax_'+tax_name).each(function(index) {
      if ($('select.tax_'+tax_name).eq(index).val().match(/(_E|_NS)$/)) {
        hide_comment = false;
      }
    });
    if ( hide_comment ) {
      $('.'+tax_name+'_comment').hide();
    }
  }
}

/*
 * Functions for received invoices view
 */

// shows form to send mail when refusing an invoice
// also hides form showed on show_accepted_form
function show_refused_form() {
  $("#invoice-refuse").show();
  $("#invoice-accept").hide();
}

// shows form to send mail when accepting an invoice
// also hides form showed on show_refused_form
function show_accepted_form() {
  $("#invoice-refuse").hide();
  $("#invoice-accept").show();
}

// https://stackoverflow.com/questions/5999118/add-or-update-query-string-parameter
function setUrlParameter(url, key, value) {
  var parts = url.split("#", 2), anchor = parts.length > 1 ? "#" + parts[1] : '';
  var query = (url = parts[0]).split("?", 2);
  if (query.length === 1)
    return url + "?" + key + "=" + value + anchor;

  for (var params = query[query.length - 1].split("&"), i = 0; i < params.length; i++)
    if (params[i].toLowerCase().startsWith(key.toLowerCase() + "="))
      return params[i] = key + "=" + value, query[query.length - 1] = params.join("&"), query.join("?") + anchor;

  return url + "&" + key + "=" + value + anchor
}
