function mostrarCapa(capa)
{
  var datos = document.getElementById(capa).style.display;
  if (datos != "none")
  {
    document.getElementById(capa + "Link").innerHTML = "Mostrar más datos";
    document.getElementById(capa).style.display="none";
  }
  else
  {
    document.getElementById(capa + "Link").innerHTML = "Ocultar";
    document.getElementById(capa).style.display="";
  }
}
function mostrarFactura(numFactura)
{
  var datos = document.getElementById(numFactura).style.display;
  if (datos != "none")
  {
    document.getElementById("lote").style.display="";
    document.getElementById("importesLote").style.display="";
    if (document.getElementById("tercero")!=null)
    {
      document.getElementById("tercero").style.display="";
    }
    document.getElementById("listadoFacturas").style.display="";
    document.getElementById("factura" + numFactura).style.display="none";
    document.getElementById(numFactura).style.display="none";
  }
  else
  {
    document.getElementById("lote").style.display="none";
    document.getElementById("importesLote").style.display="none";
    if (document.getElementById("tercero")!=null)
    {
      document.getElementById("tercero").style.display="none";
    }
    document.getElementById("listadoFacturas").style.display="none";
    document.getElementById("factura" + numFactura).style.display="";
    document.getElementById(numFactura).style.display="";
  }
}
function mostrarDetalle(numFactura,desDetalle)
{
  var datos = document.getElementById(numFactura + "_" + desDetalle).style.display;
  if (datos != "none")
  {
    document.getElementById("emisor").style.display="";
    document.getElementById("receptor").style.display="";
    if (document.getElementById("cesionario")!=null)
    {
      document.getElementById("cesionario").style.display="";
    }
    document.getElementById("factura" + numFactura).style.display="";
    document.getElementById(numFactura).style.display="";
    document.getElementById(numFactura + "_" + desDetalle).style.display="none";
  }
  else
  {
    document.getElementById("lote").style.display="none";
    document.getElementById("importesLote").style.display="none";
    document.getElementById("emisor").style.display="none";
    document.getElementById("receptor").style.display="none";
    if (document.getElementById("tercero")!=null)
    {
      document.getElementById("tercero").style.display="none";
    }
    if (document.getElementById("cesionario")!=null)
    {
      document.getElementById("cesionario").style.display="none";
    }
    document.getElementById("listadoFacturas").style.display="none";
    document.getElementById("factura" + numFactura).style.display="none";
    document.getElementById(numFactura).style.display="none";
    document.getElementById(numFactura + "_" + desDetalle).style.display="";
  }
}

function descUnidadMedida(valor)
{
  var descripcion = '';
  switch(valor) {
    case '01':
      descripcion = 'Unidades';
      break;
    case '02':
      descripcion = 'Horas-HUR';
      break;
    case '03':
      descripcion = 'Kilogramos-KGM';
      break;
    case '04':
      descripcion = 'Litros-LTR';
      break;
    case '05':
      descripcion = 'Otros';
      break;
    case '06':
      descripcion = 'Cajas-BX';
      break;
    case '07':
      descripcion = 'Bandejas-DS';
      break;
    case '08':
      descripcion = 'Barriles-BA';
      break;
    case '09':
      descripcion = 'Bidones-JY';
      break;
    case '10':
      descripcion = 'Bolsas-BG';
      break;
    case '11':
      descripcion = 'Bombonas-CO';
      break;
    case '12':
      descripcion = 'Botellas-BO';
      break;
    case '13':
      descripcion = 'Botes-CI';
      break;
    case '14':
      descripcion = 'Tetra Briks';
      break;
    case '15':
      descripcion = 'Centilitros-CLT';
      break;
    case '16':
      descripcion = 'Centímetros-CMT';
      break;
    case '17':
      descripcion = 'Cubos-BI';
      break;
    case '18':
      descripcion = 'Docenas';
      break;
    case '19':
      descripcion = 'Estuches-CS';
      break;
    case '20':
      descripcion = 'Garrafas-DJ';
      break;
    case '21':
      descripcion = 'Gramos-GRM';
      break;
    case '22':
      descripcion = 'Kilómetros-KMT';
      break;
    case '23':
      descripcion = 'Latas-CA';
      break;
    case '24':
      descripcion = 'Manojos-BH';
      break;
    case '25':
      descripcion = 'Metros-MTR';
      break;
    case '26':
      descripcion = 'Milímetros-MMT';
      break;
    case '27':
      descripcion = '6-Packs';
      break;
    case '28':
      descripcion = 'Paquetes-PK';
      break;
    case '29':
      descripcion = 'Raciones';
      break;
    case '30':
      descripcion = 'Rollos-RO';
      break;
    case '31':
      descripcion = 'Sobres-EN';
      break;
    case '32':
      descripcion = 'Tarrinas-TB';
      break;
    case '33':
      descripcion = 'Metro cúbico-MTQ';
      break;
    case '34':
      descripcion = 'Segundo-SEC';
      break;
    case '35':
      descripcion = 'Vatio-WTT';
      break;
    default:
      descripcion = valor;
      break;
  }
  return descripcion;
}

function descTipoPersona(valor)
{
  var descripcion = '';
  switch(valor) {
    case 'F':
      descripcion = 'Física';
      break;
    case 'J':
      descripcion = 'Jurídica';
      break;
    default:
      descripcion = valor;
      break;
  }
  return descripcion;
}

function descTipoResidencia(valor)
{
  var descripcion = '';
  switch(valor) {
    case 'E':
      descripcion = 'Extranjero';
      break;
    case 'R':
      descripcion = 'Residente';
      break;
    case 'U':
      descripcion = 'Residente en la Unión Europea';
      break;
    default:
      descripcion = valor;
      break;
  }
  return descripcion;
}

function descTipoRol(valor)
{
  var descripcion = '';
  switch(valor) {
    case '01':
      descripcion = 'Fiscal';
      break;
    case '02':
      descripcion = 'Receptor';
      break;
    case '03':
      descripcion = 'Pagador';
      break;
    case '04':
      descripcion = 'Comprador';
      break;
    case '05':
      descripcion = 'Cobrador';
      break;
    case '06':
      descripcion = 'Vendedor';
      break;
    case '07':
      descripcion = 'Receptor del pago';
      break;
    case '08':
      descripcion = 'Receptor del cobro';
      break;
    case '09':
      descripcion = 'Emisor';
      break;
    default:
      descripcion = valor;
      break;
  }
  return descripcion;
}

function descFormaPago(valor)
{
  var descripcion = '';
  switch(valor) {
    case '01':
      descripcion = 'Al contado';
      break;
    case '02':
      descripcion = 'Recibo Domiciliado';
      break;
    case '03':
      descripcion = 'Recibo';
      break;
    case '04':
      descripcion = 'Transferencia';
      break;
    case '05':
      descripcion = 'Letra Aceptada';
      break;
    case '06':
      descripcion = 'Crédito Documentario';
      break;
    case '07':
      descripcion = 'Contrato Adjudicación';
      break;
    case '08':
      descripcion = 'Letra de cambio';
      break;
    case '09':
      descripcion = 'Pagaré a la  Orden';
      break;
    case '10':
      descripcion = 'Pagaré No a la Orden';
      break;
    case '11':
      descripcion = 'Cheque';
      break;
    case '12':
      descripcion = 'Reposición';
      break;
    case '13':
      descripcion = 'Especiales';
      break;
    case '14':
      descripcion = 'Compensación';
      break;
    case '15':
      descripcion = 'Giro postal';
      break;
    case '16':
      descripcion = 'Cheque conformado';
      break;
    case '17':
      descripcion = 'Cheque bancario';
      break;
    case '18':
      descripcion = 'Pago contra reembolso';
      break;
    case '19':
      descripcion = 'Pago mediante tarjeta';
      break;
    default:
      descripcion = valor;
      break;
  }
  return descripcion;
}

function descTipoImpuesto(valor)
{
  var descripcion = '';
  switch(valor) {
    case '01':
      descripcion = 'IVA';
      break;
    case '02':
      descripcion = 'IPSI';
      break;
    case '03':
      descripcion = 'IGIC';
      break;
    case '04':
      descripcion = 'IRPF';
      break;
    case '05':
      descripcion = 'Otro';
      break;
    case '06':
      descripcion = 'ITPAJD';
      break;
    case '07':
      descripcion = 'IE';
      break;
    case '08':
      descripcion = 'Ra';
      break;
    case '09':
      descripcion = 'IGTECM';
      break;
    case '10':
      descripcion = 'IECDPCAC';
      break;
    case '11':
      descripcion = 'IIIMAB';
      break;
    case '12':
      descripcion = 'ICIO';
      break;
    case '13':
      descripcion = 'IMVDN';
      break;
    case '14':
      descripcion = 'IMSN';
      break;
    case '15':
      descripcion = 'IMGSN';
      break;
    case '16':
      descripcion = 'IMPN';
      break;
    case '17':
      descripcion = 'REIVA';
      break;
    case '18':
      descripcion = 'REIGIC';
      break;
    case '19':
      descripcion = 'REIPSI';
      break;
    case '20':
      descripcion = 'IPS';
      break;
    case '21':
      descripcion = 'CLEA';
      break;
    case '22':
      descripcion = 'IVPEE';
      break;
    case '23':
      descripcion = 'Impuesto sobre la producción de combustible nuclear gastado y residuos radiactivos resultantes de la generación de energía nucleoeléctrica';
      break;
    case '24':
      descripcion = 'Impuesto sobre el almacenamiento de combustible nuclear gastado y residuos radioactivos en instalaciones centralizadas';
      break;
    case '25':
      descripcion = 'IDEC';
      break;
    case '26':
      descripcion = 'Impuesto sobre las labores del tabaco en la Comunidad Autónoma de Canarias';
      break;
    case '27':
      descripcion = 'IGFEI';
      break;
    default:
      descripcion = valor;
      break;
  }
  return descripcion;
}

function descLengua(valor)
{
  var descripcion = '';
  switch(valor) {
    case 'ar':
      descripcion = 'Arabe';
      break;
    case 'be':
      descripcion = 'Bielorruso';
      break;
    case 'bg':
      descripcion = 'Búlgaro';
      break;
    case 'ca':
      descripcion = 'Catalán';
      break;
    case 'cs':
      descripcion = 'Checo';
      break;
    case 'da':
      descripcion = 'Danés';
      break;
    case 'de':
      descripcion = 'Alemán';
      break;
    case 'el':
      descripcion = 'Griego moderno';
      break;
    case 'en':
      descripcion = 'Inglés';
      break;
    case 'es':
      descripcion = 'Español';
      break;
    case 'et':
      descripcion = 'Estonio';
      break;
    case 'eu':
      descripcion = 'Vascuence';
      break;
    case 'fi':
      descripcion = 'Finlandés';
      break;
    case 'fr':
      descripcion = 'Francés';
      break;
    case 'ga':
      descripcion = 'Gaélico de Irlanda';
      break;
    case 'gl':
      descripcion = 'Gallego';
      break;
    case 'hr':
      descripcion = 'Croata';
      break;
    case 'hu':
      descripcion = 'Húngaro';
      break;
    case 'is':
      descripcion = 'Islandés';
      break;
    case 'it':
      descripcion = 'Italiano';
      break;
    case 'lv':
      descripcion = 'Letón';
      break;
    case 'lt':
      descripcion = 'Lituano';
      break;
    case 'mk':
      descripcion = 'Macedonio';
      break;
    case 'mt':
      descripcion = 'Maltés';
      break;
    case 'nl':
      descripcion = 'Neerlandés';
      break;
    case 'no':
      descripcion = 'Noruego';
      break;
    case 'pl':
      descripcion = 'Polaco';
      break;
    case 'pt':
      descripcion = 'Portugués';
      break;
    case 'ro':
      descripcion = 'Rumano';
      break;
    case 'ru':
      descripcion = 'Ruso';
      break;
    case 'sk':
      descripcion = 'Eslovaco';
      break;
    case 'sl':
      descripcion = 'Esloveno';
      break;
    case 'sq':
      descripcion = 'Albanés';
      break;
    case 'sr':
      descripcion = 'Serbio';
      break;
    case 'sv':
      descripcion = 'Sueco';
      break;
    case 'tr':
      descripcion = 'Turco';
      break;
    case 'uk':
      descripcion = 'Ucraniano';
      break;
    default:
      descripcion = valor;
      break;
  }
  return descripcion;
}
