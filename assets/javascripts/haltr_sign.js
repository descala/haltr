var clienteFirma;

function cargarMiniApplet(base, keystore)
{
	var codeBase = base;
	if (codeBase == undefined || codeBase == null) {
		codeBase = '.';
	}

	var keystoreConfig = keystore;
	if (keystoreConfig == undefined) {
		keystoreConfig = null;
	}

	var jarArchive = codeBase + '/' + "miniapplet-full.jar";
	
	var attributes = {
		id: 'miniApplet',
	 	width: 1,
		height: 1
	};
	var parameters = {
		jnlp_href: codeBase + '/miniapplet-full.jnlp',
		keystore: keystoreConfig,
		userAgent: window.navigator.userAgent,
		code: 'es.gob.afirma.miniapplet.MiniAfirmaApplet.class',
		archive: jarArchive,
		codebase: codeBase,
		java_arguments: '-Djnlp.packEnabled=true -Xms512M -Xmx512M',
		separate_jvm: true
	};

 	deployJava.runApplet(attributes, parameters, '1.6');

	clienteFirma = document.getElementById("miniApplet");
}

var KEYSTORE_WINDOWS = "WINDOWS";

var KEYSTORE_APPLE = "APPLE";

var KEYSTORE_PKCS12 = "PKCS12";

var KEYSTORE_PKCS11 = "PKCS11";

var KEYSTORE_FIREFOX = "MOZ_UNI";

function sign(dataB64, algorithm, format, params) {
	return clienteFirma.sign(dataB64, algorithm, format, params);
}

function coSign(signB64, dataB64, algorithm, format, params) {
	return clienteFirma.coSign(signB64, dataB64, algorithm, format, params);
}

function counterSign(signB64, algorithm, format, params) {
	return clienteFirma.counterSign(signB64, algorithm, format, params);
}

function getSignersStructure(signB64) {
	return clienteFirma.getSignersStructure(signB64);
}

function getBase64FromText(plainText, charset) {
	return clienteFirma.getBase64FromText(plainText, charset);
}

function getTextFromBase64(dataB64, charset) {
	return clienteFirma.getTextFromBase64(dataB64, charset);
}

function saveDataToFile(dataB64, title, fileName, extension, description) {
	return clienteFirma.saveDataToFile(dataB64, title, fileName, extension, description);
}

function getFileNameContentBase64(title, extensions, description) {
	return clienteFirma.getFileNameContentBase64(title, extensions, description);
}

function getMultiFileNameContentBase64(title, extensions, description) {
	return clienteFirma.getMultiFileNameContentBase64(title, extensions, description);
}

function getErrorMessage() {
	return clienteFirma.getErrorMessage();
}

function log(msg,level) {
  if ( !$('div.flash.'+level).length ) {
    jQuery('<div/>', {
      class: 'flash ' + level
    }).prependTo('div.controller-invoices.action-show');
  }
  if ( !$('ul#haltr_'+level+'_messages').length ) {
    jQuery('<ul/>', {
      id: 'haltr_'+level+'_messages'
    }).appendTo('div.flash.'+level)
  }
  jQuery('<li/>', {
    text: msg
  }).appendTo('#haltr_'+level+'_messages')
}

function doSign_init() {
  $('#console').val("");
  $('#console').show();
  $('#ajax-indicator').css('display','inline');
}

function doSign_end() {
  $('#ajax-indicator').css('display','none');
}

function doSign(document_url,signature_type) {
  try {
    var dataB64;
    doSign_init();
    log('Descarregant document ...','notice');
    $.ajax({
      url : document_url,
      success : function(dataB64){
        try {
          log('Cridant a la signatura ...','notice');
          // <option value="CAdES">CAdES</option>
          // <option value="Adobe PDF">PAdES</option>
          // <option value="XAdES">XAdES</option>
          // <option value="ODF">ODF</option>
          // signature_type for PDF: 'Adobe PDF'
          // signature_type for Facturae: 'XAdES Enveloped'
          var signed_document = sign(dataB64, 'SHA1withRSA', signature_type, null);
          log('Enviant document signat al servidor ...','notice');
          $.ajax({
            type: "POST",
            url: document_url,
            data: "document=" + signed_document,
            success: function(result){
              log('Document enviat al servidor.','notice');
              // Reload page in 2 seconds
              //setTimeout(function() { location.reload(); }, 2000);
            },
            error: function(e){
              log('Error al enviar el document signat.','error');
              doSign_end();
            }
          });
        } catch(e) {
          log(getErrorMessage(),'error');
          doSign_end();
        }
      },
      error: function(e){
        log('Error al descarregar el document.','error');
        doSign_end();
      }
    });
  } catch(e) {
    log(getErrorMessage(),'error');
    doSign_end();
  }
}

$(document).ready(function() {

  // if a div with id autocall exists, call function from data-function with args from data-args
  if ( $('div#autocall').length ) {
    var func = window[$('div#autocall').data('function')];
    var args = $('div#autocall').data('args').split(',');
    func.apply(this, args);
  };

});
