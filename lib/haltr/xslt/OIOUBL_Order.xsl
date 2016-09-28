<?xml version="1.0" encoding="UTF-8"?>
<!--
******************************************************************************************************************

		OIOUBL Instance Documentation

		title= OIOUBL_Order.xml
		replaces= order.xml
		publisher= "IT og Telestyrelsen"
		Creator= Finn Christensen and Charlotte Dahl Skovhus
		created= 2006-12-29
		modified= 2007-07-20
		issued= 2007-07-20
		conformsTo= UBL-Order-2.0.xsd
		description= "Stylesheet for displaying a OIOUBL-2.01 Order"
		rights= "It can be used following the Common Creative Licence"

		all terms derived from http://dublincore.org/documents/dcmi-terms/

		For more information, see www.oioubl.dk	or email oioubl@itst.dk

******************************************************************************************************************
-->
<xsl:stylesheet version="1.0"

        xmlns:xsl  = "http://www.w3.org/1999/XSL/Transform"
        xmlns:n1   = "urn:oasis:names:specification:ubl:schema:xsd:Order-2"
        xmlns:cac  = "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
        xmlns:cbc  = "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
        xmlns:ccts = "urn:oasis:names:specification:ubl:schema:xsd:CoreComponentParameters-2"
        xmlns:sdt  = "urn:oasis:names:specification:ubl:schema:xsd:SpecializedDatatypes-2"
        xmlns:udt  = "urn:un:unece:uncefact:data:specification:UnqualifiedDataTypesSchemaModule:2"
                                      exclude-result-prefixes="n1 cac cbc ccts sdt udt">


	<xsl:include href="OIOUBL_CommonTemplates.xsl"/>
	<xsl:output method="html" doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN" doctype-system="http://www.w3.org/TR/html4/loose.dtd" indent="yes"/>
	<xsl:strip-space elements="*"/>
	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="n1:Order">

		<!-- Start HTML -->
		<html>
			<head>
				<link rel="Stylesheet" type="text/css" href="HtmlDependencies/OIOUBL.css"></link>
				<title>OIOUBL-2.01 dokumentudskrivning version 1.0 release 0.21</title>
			</head>
			<body>
				<!-- Start på ordrehovedet -->
				<table border="0" width="100%" cellspacing="0" cellpadding="2">
					<tr>
						<td colspan="4">
							<img class="defaultlogo" src="HtmlDependencies/gta_default_logo.jpg" width="100%" alt="Logo"/>
						</td>
					</tr>
				</table>
				<br/>
				<table border="0" width="100%" cellspacing="0" cellpadding="2">
					<tr>
						<td>
							<!-- indsætter header -->
							<h3>
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OIOUBLOrd']"/>
								<xsl:if test="cbc:CopyIndicator ='true'"><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='CopyIndicator']"/></xsl:if>
							</h3>
						</td>
						<td/>
						<td/>
						<td/>
					</tr>
					<tr>
						<td colspan="5">
							<hr size="5"/>
						</td>
					</tr>

					<tr>
						<td>
							<!-- indsætter køberadressen -->
							<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='BuyerParty']"/></b>
							<br/>
							<xsl:apply-templates select="cac:BuyerCustomerParty"/>
							<xsl:if test="cbc:AccountingCost !=''">
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AccountingCost']"/>&#160;<xsl:value-of select="cbc:AccountingCost"/>
							</xsl:if>
						</td>
						<td>
							<!-- indsætter kontaktoplysninger -->
							<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Contact']"/></b>
							<br/>
							<xsl:apply-templates select="cac:BuyerCustomerParty/cac:Party" mode="buycuscontact"/>
						</td>
							<!-- indsætter eventuel faktureringsadresse -->
							<xsl:if test="cac:AccountingCustomerParty !=''">
								<xsl:if test="cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID != cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID">
									<xsl:if test="cac:AccountingCustomerParty/cac:Party/cac:PartyName/cbc:Name != cac:BuyerCustomerParty/cac:Party/cac:PartyName/cbc:Name">
										<td>
											<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AccountingCustomerOrd']"/></b>
											<br/>
											<xsl:apply-templates select="cac:AccountingCustomerParty"/>
										</td>
									</xsl:if>
								</xsl:if>
							</xsl:if>
							<!-- indsætter eventuel oprindelig kunde -->
							<xsl:if test="cac:OriginatorCustomerParty !=''">
								<xsl:if test="cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID != cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID">
									<xsl:if test="cac:OriginatorCustomerParty/cac:Party/cac:PartyName/cbc:Name != cac:BuyerCustomerParty/cac:Party/cac:PartyName/cbc:Name">
										<td>
											<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OriginatorCustomerParty']"/></b>
											<br/>
											<xsl:apply-templates select="cac:OriginatorCustomerParty"/>
										</td>
									</xsl:if>
								</xsl:if>
							</xsl:if>
					</tr>
					<tr>
						<td colspan="5">
							<hr size="2"/>
						</td>
					</tr>
					<tr>
						<td>
							<!-- indsætter leverandøradressen -->
							<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SellerParty']"/></b>
							<br/>
							<xsl:apply-templates select="cac:SellerSupplierParty"/>
						</td>
						<td>
							<!-- indsætter kontaktoplysninger -->
							<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Contact']"/></b>
							<br/>
							<xsl:apply-templates select="cac:SellerSupplierParty/cac:Party" mode="selsupcontact"/>
						</td>
					</tr>
					<tr>
						<td colspan="5">
							<hr size="2"/>
						</td>
					</tr>
					<!-- indsætter eventuelle leveringsoplysninger-->
					<xsl:if test="cac:Delivery !=''">
						<tr>
							<td colspan="5">
								<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Delivery']"/></b>
							</td>
						</tr>
						<xsl:apply-templates select="cac:Delivery" mode="header"/>
					</xsl:if>
					<tr>
						<td colspan="5">
							<hr size="2"/>
						</td>
					</tr>
					<tr>
						<td width="26%">
							<!-- indsætter Ordrenummer -->
							<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OrderID']"/>&#160;</b>
							<xsl:value-of select="cbc:ID"/>
						</td>
						<td width="27%">
							<!-- indsætter ordre dato -->
							<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='IssueDate']"/>&#160;</b>
							<xsl:value-of select="cbc:IssueDate"/>
						</td>
					</tr>
					<tr>
						<td colspan="5">
							<hr size="2"/>
						</td>
					</tr>
				</table>
				<!-- Slut på ordrehovedet -->

				<!--Start ordrelinje-->
				<table border="0" width="100%" cellspacing="0" cellpadding="2">
					<tr>
						<td width="15%">
							<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='LineID']"/></b>
						</td>
						<td width="15%">
							<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SellersItemIdentification']"/></b>
						</td>
						<td width="30%">
							<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ItemName']"/></b>
						</td>
						<td width="10%">
							<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Quantity']"/></b>
						</td>
						<td width="15%">
							<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='QuantityUnitCode']"/></b>
						</td>
						<td	width="15%">
							<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PriceUnit']"/></b>
						</td>
						<td width="15%" align="right">
							<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='LineExtensionAmountLine']"/></b>
							<br/>
						</td>
					</tr>
					<xsl:apply-templates select="cac:OrderLine/cac:LineItem"/>
				</table>
				<!--Slut ordrelinje-->

				<!--Start afgifter og totaler-->
				<table border="0" width="100%" cellspacing="0" cellpadding="2">
					<tr>
						<td colspan="7">
							<hr size="2"/>
						</td>
					</tr>
					<!-- Linjesum -->
					<xsl:if test="cac:AnticipatedMonetaryTotal/cbc:LineExtensionAmount !=''">
						<xsl:apply-templates select="cac:AnticipatedMonetaryTotal" mode="LineTotal"/>
					</xsl:if>
					<!-- Afgifter på header -->
					<xsl:apply-templates select="cac:TaxTotal" mode="afgift"/>
					<!-- Rabat og gebyr på header -->
					<xsl:apply-templates select="cac:AllowanceCharge" mode="total"/>
					<!--Moms på header -->
					<xsl:apply-templates select="cac:TaxTotal" mode="moms"/>
					<!-- Ordretotal  -->
					<xsl:if test="cac:AnticipatedMonetaryTotal/cbc:PayableAmount !=''">
						<xsl:apply-templates select="cac:AnticipatedMonetaryTotal" mode="Total"/>
					</xsl:if>
					<tr>
						<td colspan="7">
							<hr size="5"/>
						</td>
					</tr>
				</table>
				<!--Slut afgifter og totaler-->

				<!-- Start på fritekst og referencer-->
				<table border="0" width="100%" cellspacing="0" cellpadding="2">
					<tr>
						<td colspan="4">
							<xsl:if test="cac:ValidityPeriod !=''">
								<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ValidityPeriod']"/></b>&#160;<xsl:apply-templates select="cac:ValidityPeriod"/><br/>
							</xsl:if>
							<xsl:if test="cbc:Note[.!='']">
								<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Notes']"/></b>&#160;<xsl:apply-templates select="cbc:Note"/><br/>
							</xsl:if>
							<xsl:if test="cac:Contract !=''">
								<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ContractDocumentReferenceID']"/></b>&#160;<xsl:apply-templates select="cac:Contract"/><br/>
							</xsl:if>
							<xsl:if test="cac:QuotationDocumentReference/cbc:ID !=''">
								<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='QuotationDocumentReference']"/></b>&#160;<xsl:apply-templates select="cac:QuotationDocumentReference"/><br/>
							</xsl:if>
							<xsl:if test="cac:AdditionalDocumentReference/cbc:ID !=''">
								<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AdditionalDocumentReferenceID']"/></b>&#160;<xsl:apply-templates select="cac:AdditionalDocumentReference"/><br/>
							</xsl:if>
						</td>
					</tr>
				</table>
				<!-- Slut på fritekst og referencer-->

				<!-- Start på OIOUBL footer -->
				<table border="0" width="100%" cellspacing="0" cellpadding="2">
					<tr>
						<td colspan="3">
							<hr size="2"/>
						</td>
					</tr>
					<tr>
						<td>
							<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OIOUBLDoc']"/></b>
							<br/>
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='VersionID']"/>&#160;<xsl:value-of select="cbc:UBLVersionID"/>
							<br/>
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='CustomizationID']"/>&#160;<xsl:value-of select="cbc:CustomizationID"/>
							<br/>
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ProfileID']"/>&#160;<xsl:value-of select="cbc:ProfileID"/>
							<br/>
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ID']"/>&#160;<xsl:value-of select="cbc:ID"/>
							<br/>
							<xsl:if test="cbc:UUID !=''">
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='UUID']"/>&#160;<xsl:value-of select="cbc:UUID"/>
							</xsl:if>
							<br/>
							<xsl:if test="cbc:RequestedInvoiceCurrencyCode !=''">
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='RequestedInvoiceCurrencyCode']"/>&#160;<xsl:value-of select="cbc:RequestedInvoiceCurrencyCode"/>
							<br/>
							</xsl:if>
							<xsl:if test="cbc:DocumentCurrencyCode !=''">
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DocumentCurrencyCode']"/>&#160;<xsl:value-of select="cbc:DocumentCurrencyCode"/>
							<br/>
							</xsl:if>
							<xsl:if test="cbc:PricingCurrencyCode !=''">
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PricingCurrencyCode']"/>&#160;<xsl:value-of select="cbc:PricingCurrencyCode"/>
							<br/>
							</xsl:if>
							<xsl:if test="cbc:TaxCurrencyCode !=''">
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxCurrencyCode']"/>&#160;<xsl:value-of select="cbc:TaxCurrencyCode"/>
							<br/>
							</xsl:if>

						</td>
						<xsl:if test="cac:Signature !=''">
							<td>
								<xsl:apply-templates select="cac:Signature"/>
							</td>
						</xsl:if>
					</tr>
				</table>
				<!-- Slut på OIOUBL footer -->
			</body>
		</html>
	</xsl:template>

</xsl:stylesheet>
