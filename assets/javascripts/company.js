/**
 * When tax category set to exempt, shows
 * comment and hides percent text_fields
 */
$(document).on('change', 'select.tax_category', function(e) {
  var $this = $(this);
  var sel = $this.val();
  var span_percent = $this.parent().parent().find(".span_percent");
  var span_comment = $this.parent().parent().find(".span_comment");
  var field_percent = span_percent.children();
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
});

$(document).on('change', 'select#invoice_mail_customization_lang', function(e) {
  var lang = $(this).val();
  $('div.invoice_mail_customization').each(function(i,obj) {
    $(obj).hide();
  });
  $('div#invoice_mail_customization_'+lang).show();
});

$(document).ready(function() {
  $('div#invoice_mail_customization_'+$('select#invoice_mail_customization_lang').val()).show();
});

$(document).on('change', 'select#quote_mail_customization_lang', function(e) {
  var lang = $(this).val();
  $('div.quote_mail_customization').each(function(i,obj) {
    $(obj).hide();
  });
  $('div#quote_mail_customization_'+lang).show();
});

$(document).ready(function() {
  $('div#quote_mail_customization_'+$('select#quote_mail_customization_lang').val()).show();
});

$(document).on('change','input#logo', function(e) {
  if ($(this).val().match(/%/)) {
    alert('filename contains invalid characters: %');
    $(this).val('');
  }
});
