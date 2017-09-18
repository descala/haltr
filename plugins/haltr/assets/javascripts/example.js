var signature;
var mobile = false;
var filename;
var divMensaje = document.getElementById('divmensaje');
var btn_firmar = document.getElementById('saveFile');
var saveExtension = "*.csig";
var saveDescription = "Firma avanzada CAdES (*.csig)";

if ((MiniApplet.isAndroid()==true) || (MiniApplet.isIOS()==true) || (MiniApplet.isWindowsRT()==true) || (MiniApplet.isWindows8ModernUI()==true)) {
  mobile = true;
}

function firmar(){
  btn_firmar.disabled = true;

  var dataB64 = null;
  var params;
  var formato = "CAdES";
  try {

    if (mobile==true) {

      params = "mode=explicit\n" + "serverUrl=https://valide.redsara.es/firmaMovil/TriPhaseSignerServer/SignatureService";

    }
    else {

      params = "mode=implicit";

      var fichero = MiniApplet.getFileNameContentBase64("Selecciona un archivo ", "", "");

      var separatorIdx = fichero.indexOf("|");
      if ((separatorIdx + 1) < fichero.length) {
        filename = fichero.substring(0, separatorIdx);
        dataB64 = fichero.substring(separatorIdx + 1);

        var extension = getExtension(filename) + "";
        extension = extension.toUpperCase();

        if (extension == "PDF") {
          formato = "PAdES"; //:Adobe PDF/PAdES
          saveExtension = "*.pdf";
          saveDescription = "Adobe PDF (*.pdf)";
        }
        else {
          if (extension == "XML" || extension == "XSIG") {
            formato = "XAdES Enveloping";
            saveExtension = "*.xsig";
            saveDescription = "Firma XML (*.xsig, *.xml)";
          }
        }
      }

    }

  }
  catch (e) {
    //Se muestra el mensaje de error si NO es de cancelación de la operación
    if (e.message.indexOf("AOCancelledOperationException")==-1) {
      divMensaje.innerHTML='<br><div class="iconErrorFirma">Error al firmar</div><br>';
    }
  }

  MiniApplet.sign(dataB64, "SHA1withRSA", formato, params, successCallback, errorCallback);

}

function guardarFirma(){        
  if (mobile==true) {
    MiniApplet.saveDataToFile(signature, "Guardar firma", "firma.csig", saveExtension, saveDescription);
  }
  else {
    MiniApplet.saveDataToFile(signature, "Guardar firma", null, saveExtension, saveDescription);
  }
}

function getExtension(filename){
  return (/[.]/.exec(filename)) ? /[^.]+$/.exec(filename) : undefined;
}

function mostrarPantalla()  {
  document.getElementById("cargandoApplet").style.display = "none";
  document.getElementById("pantalla").style.display = "block";
  if (mobile==true) {
    document.getElementById("firmaProceso1").style.display = "none";

    if (MiniApplet.isAndroid()) {
      document.getElementById("firmaProcesoAND").style.display = "inline";
    }
    else if (MiniApplet.isIOS()) {
      document.getElementById("firmaProcesoIOS").style.display = "inline";
    }
    else {
      document.getElementById("firmaProcesoW8").style.display = "inline";
    }
    document.getElementById("saveFile").style.display = "none";
    document.getElementById("clienteEscritorio").style.display = "none";
    document.getElementById("nota").style.display = "none";
    document.getElementById("nota2").style.display = "inline";
  }
}

function successCallback(signatureB64) {

  signature = signatureB64;

  var divMensaje = document.getElementById('divmensaje');
  if (mobile==false) {
    divMensaje.innerHTML='<br><div class="iconOKFirma">Fichero firmado correctamente</div><br>' + filename + '<br>';
    btn_firmar.disabled = false;
  }
  else {
    divMensaje.innerHTML='<br><div class="iconOKFirma">Fichero firmado correctamente</div>';
  }

  var divFirma = document.getElementById('divfirma');
  var content = '<br><textarea id="firmaB64" cols="76" rows="6">' + signatureB64 + '</textarea><br>';
  if (!MiniApplet.isIOS() && !MiniApplet.isWindows8()) {
    document.getElementById("saveFile").style.display = "inline";
    document.getElementById("saveFile").disabled = false;
  }

  divFirma.innerHTML = content;
}

function errorCallback(errorType, errorMessage) {
  if (errorMessage.indexOf("AOCancelledOperationException")==-1) {
    if (errorMessage.indexOf("El almacen no contenia entradas")!=-1) {
      divMensaje.innerHTML='<br><br><img class="iconStatus" src="/valide/img/iconFALLO.png">No existen certificados en el almacén de su navegador<br><br>';
    }
    else {
      divMensaje.innerHTML='<br><div class="iconErrorFirma">Error al firmar</div><br><div style="width:300pt">' + errorMessage + '</div><br>';
    }
  }
}

mostrarPantalla();

