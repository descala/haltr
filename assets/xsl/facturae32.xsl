<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<xsl:stylesheet version="1.0" xmlns:facturae="http://www.facturae.es/Facturae/2009/v3.2/Facturae"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xd">
    <xsl:output method="html" encoding="UTF-8" omit-xml-declaration="yes"
        doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
        doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd" indent="yes"/>

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Nov 20, 2010</xd:p>
            <xd:p><xd:b>Author:</xd:b> oriolbausa</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:decimal-format name="Importe" decimal-separator="." grouping-separator=","/>
    
    
    <xsl:variable name="lang"><xsl:value-of select="//LanguageName"/></xsl:variable>
    
<xsl:template match="facturae:Facturae">
    
    <html xml:lang="en" xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
            <title><xsl:value-of
                select="document(concat('/plugin_assets/haltr/xsl/trans_',$lang,'.xml'))/diccionari/element[@etiqueta='Invoice']"/></title>
            <!-- link href="/stylesheets/application.css?1288878280" media="all" rel="stylesheet" type="text/css" / -->            
            <link href="http://www.b2brouter.net/plugin_assets/haltr/stylesheets/print.css" media="print" rel="stylesheet" type="text/css" />            
            <!-- link href="/plugin_assets/haltr/stylesheets/minimal.css?1289397738" media="screen" rel="stylesheet" type="text/css" / -->

        </head>
        <body>
            <div id="invoice_wrapper">
        
        <!-- Wrapper -->
        <div id="invoice_wrapper">
            
            <!-- Workspace -->
            
            <div id="workspace1" class="haltrinvoice received">
                <div id="workspace2">
                
                <div id="col1">
                    <!-- BEGIN Standard Invoice Markup -->
                    <xsl:apply-templates select="//Parties/SellerParty"/>
                    
                    
                    <!-- Invoice Number and Info -->
                    <h2 class="invoice-ID"><xsl:value-of
                        select="document(concat('/plugin_assets/haltr/xsl/trans_',$lang,'.xml'))/diccionari/element[@etiqueta='Invoice']"/><xsl:value-of select="concat(' ',//InvoiceNumber)"/></h2>
                    <div class="invoice-info">
                        <span class="date"><strong><xsl:value-of select="//IssueDate"/></strong></span><br/>
                        <xsl:apply-templates select="//Installment"/>
                        
                    </div>
                    <xsl:apply-templates select="//Parties/BuyerParty"/>

                    <!-- Invoice Data -->
                    <div class="invoice">
                        
                        <!-- Line Details -->    
                        <table class="line-items" border="0" cellpadding="0" cellspacing="0">
                            <tbody>
                                <tr>
                                    
                                    <th class="item-quantity first"><abbr title="Quantitat">Q</abbr></th>
                                    <th class="item-description">
                                        <span>
                                            <xsl:value-of
                                                select="document(concat('/plugin_assets/haltr/xsl/trans_',$lang,'.xml'))/diccionari/element[@etiqueta='Description']"/>
                                        </span>
                                    </th>
                                    <th class="item-price"><xsl:value-of
                                        select="document(concat('/plugin_assets/haltr/xsl/trans_',$lang,'.xml'))/diccionari/element[@etiqueta='Amount']"/></th>
                                    <th class="line-total last">                        <xsl:value-of
                                        select="document(concat('/plugin_assets/haltr/xsl/trans_',$lang,'.xml'))/diccionari/element[@etiqueta='Total']"/></th>
                                </tr>
                                
                                <xsl:apply-templates select="//InvoiceLine"/>
                                
                                
                            </tbody></table>
                        
                        
                        <!-- Totals Details -->
                        <table class="invoice-calculations" border="0" cellpadding="0" cellspacing="0">
                            <tbody><tr class="invoice-subtotal">
                                <th><xsl:value-of
                        select="document(concat('/plugin_assets/haltr/xsl/trans_',$lang,'.xml'))/diccionari/element[@etiqueta='Subtotal']"/>:</th>
                                <td><xsl:value-of select="concat(//TotalGrossAmountBeforeTaxes,' ',//InvoiceCurrencyCode)"/></td>
                            </tr>
                                <xsl:apply-templates select="//Invoice/TaxesOutputs/Tax"/>
                                <xsl:apply-templates select="//Invoice/TaxesWithheld/Tax"/>
                                
                                <tr class="invoice-total">
                                    <th><xsl:value-of
                        select="document(concat('/plugin_assets/haltr/xsl/trans_',$lang,'.xml'))/diccionari/element[@etiqueta='Total']"/>:</th>
                                    <td><xsl:value-of select="concat(//TotalExecutableAmount,' ',//InvoiceCurrencyCode)"/></td>
                                </tr>
                            </tbody></table>
                        
                        
                    </div>
                    
                    <div class="notes">
                        <h3>                      <xsl:value-of
                            select="document(concat('/plugin_assets/haltr/xsl/trans_',$lang,'.xml'))/diccionari/element[@etiqueta='Notes']"/></h3>
                        <span class="invoice-terms"><p><xsl:value-of select="//InvoiceAdditionalInformation"/></p></span><br/>
                    </div>
                    
                    <!-- END Standard Invoice Markup -->
                </div>
                </div>
      </div>
            
        </div>
    </div>  
    </body>
 </html>
    
</xsl:template>    

<xsl:template match="SellerParty">
    <!-- Vendor Info -->
    <div class="vcard vendor">
        <div class="logo">
            <xsl:element name="img">
                <xsl:attribute name="alt"><xsl:value-of select="LegalEntity/CorporateName"/></xsl:attribute>
                <xsl:attribute name="src">http://www.b2brouter.net/companies/logo/<xsl:value-of select="TaxIdentification/TaxIdentificationNumber"/></xsl:attribute>
            </xsl:element>
        </div>

        <div class="vendor-info">
            <h3 class="org fn">
                <xsl:choose>
                    <xsl:when test="LegalEntity/CorporateName"><xsl:value-of select="LegalEntity/CorporateName"/></xsl:when>
                    <xsl:when test="Individual"><xsl:value-of select="(concat(Individual/Name,' ',Individual/FirstSurname,' ',Individual/SecondSurname))"/></xsl:when>
                </xsl:choose>
                </h3>
            <address class="adr">
               <div class="street-address"><xsl:value-of select="(LegalEntity|Individual)/*/Address"/></div>
               <span class="postal-code"><xsl:value-of select="(LegalEntity|Individual)/*/PostCode"/></span> <span class="locality"><xsl:value-of select="(LegalEntity|Individual)/*/Town"/></span>
              <span class="postal-code"><xsl:value-of select="(LegalEntity|Individual)/*/PostCodeAndTown"/></span>
               <div class="region"><xsl:value-of select="(LegalEntity|Individual)/*/Province"/></div>

               <div class="country-name"><xsl:value-of select="(LegalEntity|Individual)/*/CountryCode"/></div>
            </address>
            <div><strong> <xsl:value-of
                select="document(concat('/plugin_assets/haltr/xsl/trans_',$lang,'.xml'))/diccionari/element[@etiqueta='VAT Nbr']"/>:</strong><span class="tax-id"><xsl:value-of select="TaxIdentification/TaxIdentificationNumber"/></span></div>
            <div style="height:10px;"></div>
            
            <xsl:apply-templates select="(LegalEntity|Individual)/*/WebAddress"/>
            <xsl:apply-templates select="(LegalEntity|Individual)/*/ElectronicMail"/>
            
        </div>
    </div>
    
</xsl:template>

<xsl:template match="BuyerParty">
    <!-- Client Info -->
    <div class="vcard client">
        <div class="client-info">
            <h3 class="org fn">
            <xsl:choose>
                <xsl:when test="LegalEntity/CorporateName"><xsl:value-of select="LegalEntity/CorporateName"/></xsl:when>
                <xsl:when test="Individual"><xsl:value-of select="(concat(Individual/Name,' ',Individual/FirstSurname,' ',Individual/SecondSurname))"/></xsl:when>
            </xsl:choose>
            </h3>
            <address class="adr">

              <div class="street-address"><xsl:value-of select="(LegalEntity|Individual)/*/Address"/></div>
              <div class="street-address"></div>
              <span class="postal-code"><xsl:value-of select="(LegalEntity|Individual)/*/PostCode"/></span>
              <span class="postal-code"><xsl:value-of select="(LegalEntity|Individual)/*/PostCodeAndTown"/></span>
            <span class="locality"><xsl:value-of select="(LegalEntity|Individual)/*/Town"/></span>&nbsp;<span class="region"><xsl:value-of select="(LegalEntity|Individual)/*/Province"/></span>              <div class="country-name"><xsl:value-of select="(LegalEntity|Individual)/*/CountryCode"/></div>
            </address>
            <div><strong><xsl:value-of
                select="document(concat('/plugin_assets/haltr/xsl/trans_',$lang,'.xml'))/diccionari/element[@etiqueta='VAT Nbr']"/>:</strong><span class="tax-id"> <xsl:value-of select="TaxIdentification/TaxIdentificationNumber"/></span></div>
            <div style="height:10px;"></div>
            
            <xsl:apply-templates select="(LegalEntity|Individual)/*/WebAddress"/>
            <xsl:apply-templates select="(LegalEntity|Individual)/*/ElectronicMail"/>
            
        </div>
    </div>
    
</xsl:template>

<xsl:template match="WebAddress">
    <div>
    <xsl:element name="a">
        <xsl:attribute name="href"><xsl:value-of select="."/></xsl:attribute>
        <xsl:attribute name="class">url</xsl:attribute>
        <xsl:attribute name="target">_blank</xsl:attribute>
        <xsl:value-of select="."/>
    </xsl:element>
    </div>
</xsl:template>
    
<xsl:template match="ElectronicMail">
    <div>
        <xsl:element name="a">
            <xsl:attribute name="href"><xsl:value-of select="."/></xsl:attribute>
            <xsl:attribute name="class">url</xsl:attribute>
            <xsl:attribute name="target">_blank</xsl:attribute>
            <xsl:value-of select="."/>
        </xsl:element>
    </div>
</xsl:template>

<xsl:template match="Installment">
    
    <span class="invoice-terms"><xsl:value-of
        select="document(concat('/plugin_assets/haltr/xsl/trans_',$lang,'.xml'))/diccionari/element[@etiqueta='Installment']"/> <xsl:value-of select="concat(' ',InstallmentDueDate)"/></span><br/>
    <span class="invoice-terms">
        <xsl:variable name="valuetype" select="PaymentMeans"/>
        <xsl:value-of
        select="document('/plugin_assets/haltr/xsl/PaymentMeansCodeAEAT-1.0.gc')//SimpleCodeList[1]/Row/Value[@ColumnRef='code']/SimpleValue[.=$valuetype]/../../Value[@ColumnRef=$lang]/SimpleValue"/>
        <xsl:value-of select="concat(' ',(AccountToBeDebited|AccountToBeCredited)/AccountNumber)"/></span><br/>
</xsl:template>
    
<xsl:template match="InvoiceLine">
            
            <tr>
                
                <td class="item-quantity first"><xsl:value-of select="Quantity"/></td>
                <td class="item-description"><xsl:value-of select="ItemDescription"/></td>
                <td class="item-price"><xsl:value-of select='format-number(UnitPriceWithoutTax, "#.00", "Importe")'/></td>
                <td class="line-total last"><xsl:value-of select='format-number(TotalCost, "#.00", "Importe")'/></td>
            </tr>
            
            
</xsl:template>

<xsl:template match="Tax">
    <xsl:variable name="valuetype"><xsl:value-of select="TaxTypeCode"/></xsl:variable>
    <tr class="sales-tax">
        <th><xsl:value-of
            select="document('/plugin_assets/haltr/xsl/TaxCodeAEAT-1.0.gc')//SimpleCodeList[1]/Row/Value[@ColumnRef='code']/SimpleValue[.=$valuetype]/../../Value[@ColumnRef=$lang]/SimpleValue"/>
            <xsl:value-of select="concat(' ',format-number(TaxRate,'#'),'%')"/>:</th>
        
        <td><xsl:value-of select="TaxAmount/TotalAmount"/></td>
    </tr>
</xsl:template>

</xsl:stylesheet>
