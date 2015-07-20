/**
 * PDF page settings.
 * Must have the correct values for the script to work.
 * All numbers must be in inches (as floats)!
 * '/25.4' part is a converstiom from mm to in.
 *
 * @type {Object}
 */
var pdfPage = {
  width: 8.3, // inches
  height: 11.7, // inches
  margins: {
    top: 2/25.4,
    left: 2/25.4,
    right: 2/25.4,
    bottom: 40/25.4
  }
};

/**
 * Class name of the tables to automatically split.
 * Should not contain any CSS definitions because it is automatically removed
 * after the split.
 *
 * @type {String}
 */
var splitClassName = 'splitForPrint';

$(window).load(function() {

  var dpi = 120;
  var pageWidth = (pdfPage.width - pdfPage.margins.left - pdfPage.margins.right) * dpi;
  // page height in pixels
  var pageHeight = (pdfPage.height - pdfPage.margins.top - pdfPage.margins.bottom) * dpi;
  // temporary set body's width and margin to match pdf's size

  var $body = $('body .invoice_data'); //a single div should wrap whole pdf content
  $body.css('width', pageWidth);
  $body.css('margin-left', pdfPage.margins.left + 'in');
  $body.css('margin-right', pdfPage.margins.right + 'in');
  $body.css('margin-top', pdfPage.margins.top + 'in');
  $body.css('margin-bottom', pdfPage.margins.bottom + 'in');

  var pageHeader = $('div.invoice-header').clone();
  var tableToSplit = $('table.' + splitClassName);
  if (tableToSplit.length > 0) {
    tableToSplit.detach();
  }
  var totals = $('table.invoice-calculations').detach();
  var notes = $('div.notes').detach();
  var companyid = $('p.companyid').detach();

  var pages = 1;
  var breaker = $('<div class="page-break" />');
  var pageNum = $('<div class="page-num" />')
  var nextBreakAt = pageHeight;
  var templateTable = tableToSplit.clone();
  templateTable.find('tbody > tr').remove();

  var currentTable = templateTable.clone();
  $body.append(currentTable);

  function break_page() {
    pages += 1;
    $body.append(pageNum.clone());
    nextBreakAt += pageHeight;
    $body.append(breaker.clone());
    $body.append(pageHeader.clone());
  }

  function append_and_break_if_needed(to_append) {
    if (($body.outerHeight() + to_append.outerHeight()) > nextBreakAt) {
      break_page();
    }
    $body.append(to_append);
  }

  var total_rows = $('tbody tr', tableToSplit).size();

  $('tbody tr', tableToSplit).each(function(index) {
    if (($body.outerHeight() + $(this).outerHeight()) > nextBreakAt) {
      break_page();
      currentTable = templateTable.clone();
      $body.append(currentTable);
    }
    // at least one line on the last page
    if (index + 1 == total_rows) {
      var auxDiv = $('<div />');
      $('tbody tr:nth-last-child(-n+5)', tableToSplit).each(function(index) {
         auxDiv.append($(this).clone());
      });
      auxDiv.append(totals.clone());
      auxDiv.append(notes.clone());
      auxDiv.append(companyid.clone());
      auxDiv.append(pageNum.clone());
      $body.append(auxDiv);
      var auxSize = $body.outerHeight();
      auxDiv.remove();
      if (auxSize > nextBreakAt) {
        break_page();
        currentTable = templateTable.clone();
        $body.append(currentTable);
      }
    }
    currentTable.append($(this));
  });

  append_and_break_if_needed(totals);
  append_and_break_if_needed(notes);
  append_and_break_if_needed(companyid);

  $body.append(pageNum.clone());

  // page numbers
  var i = 0;
  while (i <= pages) {
    var divNum = $('div.page-num:eq(' + i + ')');
    i += 1;
    if (divNum.length > 0) {

      //divNum.css('position', 'fixed');
      //divNum.css('top', (divNum.offset().top + 250 )+'px');
      divNum.css('float', 'left');
      divNum.css('clear', 'both');
      divNum.css('margin-top', '250px');
      divNum.append('<p>Page '+i+' of '+pages+'</p>');
    }
  }

  // restore body's margin
  $body.css('margin-left',   0);
  $body.css('margin-right',  0);
  $body.css('margin-top',    0);
  $body.css('margin-bottom', 0);
});
