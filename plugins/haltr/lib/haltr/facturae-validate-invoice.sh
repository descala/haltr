#!/bin/sh

# Scraps mityc web validation tool
# Usage: facturae-validate-invoice [xml_invoice]
# Returns 0 if invoice is valid, 1 otherwise 

OUTPUT=$(curl -s -F "formato=formato" -F "contable=contable" -F "firma=firma" -F "factura=@$1;type=text/xml" "http://www11.mityc.es/FacturaE/ValidarCompleto") 

echo "$OUTPUT" | grep -o "\/.*title=.*\" "

echo "$OUTPUT" | grep -A 1 "errormsg.*"

# Bash's exit status is the exit status of the last command executed in the script
echo $OUTPUT | grep -qv "error.jpg"
