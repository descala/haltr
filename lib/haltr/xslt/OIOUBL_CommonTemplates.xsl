<?xml version="1.0" encoding="utf-8"?>
<!--
******************************************************************************************************************

		OIOUBL Instance Documentation

		title= OIOUBL_CommonTemplates.xml
		replaces= OIOUBL_CommonTemplates.xml
		publisher= "IT og Telestyrelsen"
		Creator= Finn Christensen and Charlotte Dahl Skovhus
		created= 2006-12-29
		modified= 2007-07-20
		issued= 2007-07-20
		conformsTo= UBL-Invoice-2.0.xsd
		description= "Common templates for displaying OIOUBL-2.01 documents"
		rights= "It can be used following the Common Creative Licence"

		all terms derived from http://dublincore.org/documents/dcmi-terms/

		For more information, see www.oioubl.dk	or email oioubl@itst.dk

******************************************************************************************************************
-->
<xsl:stylesheet version="1.0"

        xmlns:xsl  = "http://www.w3.org/1999/XSL/Transform"
        xmlns:n1   = "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
        xmlns:cac  = "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
        xmlns:cbc  = "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
        xmlns:ccts = "urn:oasis:names:specification:ubl:schema:xsd:CoreComponentParameters-2"
        xmlns:sdt  = "urn:oasis:names:specification:ubl:schema:xsd:SpecializedDatatypes-2"
        xmlns:udt  = "urn:un:unece:uncefact:data:specification:UnqualifiedDataTypesSchemaModule:2"
                                     exclude-result-prefixes="n1 cac cbc ccts sdt udt">


	<xsl:variable name="moduleDoc" select="document('OIOUBL_Headlines.xml')"/>

	<!--Party templates herfra-->
	<xsl:template match="cac:BuyerCustomerParty | cac:SellerSupplierParty | cac:AccountingSupplierParty | cac:AccountingCustomerParty | cac:OriginatorCustomerParty">
		<div class="UBLBuyerCustomerParty">
			<xsl:apply-templates select="cac:Party"/>
		</div>
	</xsl:template>
	<xsl:template match="cac:Party | cac:PayeeParty | cac:SenderParty | cac:ReceiverParty | cac:DeliveryParty | cac:SignatoryParty | cac:OriginatorParty">
		<div class="UBLPayeeParty">
			<xsl:apply-templates select="cac:PartyName"/>
			<xsl:apply-templates select="cac:PostalAddress"/>
			<xsl:apply-templates select="cbc:EndpointID"/>&#160; (<xsl:value-of select="cbc:EndpointID/@schemeID"/>,&#160;<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='EndpointID']"/>)
			<xsl:apply-templates select="cac:PartyIdentification"/>
			<xsl:apply-templates select="cac:PartyLegalEntity"/>
			<xsl:apply-templates select="cac:PartyTaxScheme"/>
		</div>
	</xsl:template>
	<xsl:template match="cac:PartyName">
		<xsl:if test="cbc:Name !=''">
			<div class="UBLPartyName">
				<xsl:apply-templates select="cbc:Name"/>
			</div>
		</xsl:if>
	</xsl:template>
	<xsl:template match="cac:PostalAddress | cac:DeliveryAddress | cac:Address | cac:JurisdictionRegionAddress | cac:OriginAddress">
		<xsl:choose>
			<xsl:when test="cbc:AddressFormatCode ='StructuredDK'">
				<div class="UBLPostalAddress">
					<div>
						<span class="UBLStreetName">
							<xsl:apply-templates select="cbc:StreetName"/>
						</span>
						<span class="UBLBuildingNumber">
							&#160;<xsl:apply-templates select="cbc:BuildingNumber"/>
						</span>
						<xsl:if test="cbc:Floor !=''">
							<span class="UBLFloor">
								&#160;<xsl:apply-templates select="cbc:Floor"/>
							</span>
						</xsl:if>
					</div>
					<div>
						<xsl:if test="cbc:Postbox !=''">
							<span>
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Postbox']"/><xsl:apply-templates select="cbc:Postbox"/>
							</span>
						</xsl:if>
					</div>
					<div>
						<xsl:apply-templates select="cac:Country"/>-<span class="UBLPostalZone">
							<xsl:apply-templates select="cbc:PostalZone"/>&#160;
						</span>
						<span class="UBLCityName">
							<xsl:apply-templates select="cbc:CityName"/>
						</span>
					</div>
					<div>
						<xsl:if test="cbc:Department !=''">
							<span>
								<xsl:apply-templates select="cbc:Department"/>
							</span>
						</xsl:if>
					</div>
				</div>
			</xsl:when>
			<xsl:when test="cbc:AddressFormatCode ='StructuredID'">
				<div class="UBLPostalAddress">
					<span class="UBLID">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AddressID']"/>&#160;<xsl:apply-templates select="cbc:ID"/>
					</span>
				</div>
			</xsl:when>
			<xsl:when test="cbc:AddressFormatCode ='StructuredRegion'">
				<div class="UBLPostalAddress">
					<xsl:if test="cbc:District !=''">
						<span>
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AddressDistrict']"/>&#160; <xsl:apply-templates select="cbc:District"/><br/>
						</span>
					</xsl:if>
					<xsl:if test="cbc:Region !=''">
						<span>
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AddressRegion']"/>&#160; <xsl:apply-templates select="cbc:Region"/><br/>
						</span>
					</xsl:if>
					<xsl:if test="cac:Country/cbc:IdentificationCode !=''">
						<span>
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AddressCountry']"/>&#160; <xsl:apply-templates select="cac:Country"/>
						</span>
					</xsl:if>
				</div>
			</xsl:when>
			<xsl:when test="cbc:AddressFormatCode ='StructuredLax'">
				<div class="UBLPostalAddress">
					<div>
						<span class="UBLMarkAttention">
							<xsl:if test="cbc:MarkAttention !=''">
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='MarkAttention']"/>&#160; <xsl:apply-templates select="cbc:MarkAttention"/><br/>
							</xsl:if>
						</span>
						<span class="UBLMarkCare">
							<xsl:if test="cbc:MarkCare !=''">
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='MarkCare']"/>&#160; <xsl:apply-templates select="cbc:MarkCare"/><br/>
							</xsl:if>
						</span>
						<span class="UBLID">
							<xsl:if test="cbc:ID !=''">
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AddressID']"/>&#160;<xsl:apply-templates select="cbc:ID"/><br/>
							</xsl:if>
						</span>
						<span class="UBLStreetName">
							<xsl:apply-templates select="cbc:StreetName"/>
						</span>
						<span class="UBLBuildingNumber">
							&#160;<xsl:apply-templates select="cbc:BuildingNumber"/>
						</span>
						<xsl:if test="cbc:Floor !=''">
							<span class="UBLFloor">
								&#160;<xsl:apply-templates select="cbc:Floor"/><br/>
							</span>
						</xsl:if>
						<xsl:if test="cbc:Room !=''">
							<span class="UBLRoom">
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AddressRoom']"/>&#160;<xsl:apply-templates select="cbc:Room"/><br/>
							</span>
						</xsl:if>
						<xsl:if test="cbc:BuildingName !=''">
							<span class="UBLBuildingName">
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AddressBuildingName']"/>&#160; <xsl:apply-templates select="cbc:BuildingName"/><br/>
							</span>
						</xsl:if>
						<xsl:if test="cbc:AdditionalStreetName !=''">
							<span class="UBLAdditionalStreetName">
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AddressAdditionalStreet']"/>&#160; <xsl:apply-templates select="cbc:AdditionalStreetName"/><br/>
							</span>
						</xsl:if>
						<xsl:if test="cbc:Postbox !=''">
							<span>
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Postbox']"/><xsl:apply-templates select="cbc:Postbox"/><br/>
							</span>
						</xsl:if>
					</div>
					<div>
						<xsl:if test="cbc:PostalZone !='' or cbc:CityName !=''">
							<span class="UBLPostalZone">
								<xsl:apply-templates select="cbc:PostalZone"/>&#160;
							</span>
							<span class="UBLCityName">
								<xsl:apply-templates select="cbc:CityName"/>
							</span>
						</xsl:if>
					</div>
					<div>
						<xsl:if test="cac:Country/cbc:IdentificationCode !=''">
							<span>
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AddressCountry']"/>&#160; <xsl:apply-templates select="cac:Country"/>
							</span>
						</xsl:if>
					</div>
					<div>
						<xsl:if test="cbc:Department !=''">
							<span>
								<xsl:apply-templates select="cbc:Department"/><br/>
							</span>
						</xsl:if>
						<xsl:if test="cbc:District !=''">
							<span>
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AddressDistrict']"/>&#160; <xsl:apply-templates select="cbc:District"/><br/>
							</span>
						</xsl:if>
						<xsl:if test="cbc:Region !=''">
							<span>
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AddressRegion']"/>&#160; <xsl:apply-templates select="cbc:Region"/><br/>
							</span>
						</xsl:if>
					</div>
				</div>
			</xsl:when>
			<xsl:when test="cbc:AddressFormatCode ='Unstructured'">
				<div class="UBLPostalAddress">
					<span class="UBLAddressLine">
						<xsl:apply-templates select="cac:AddressLine"/>
					</span>
				</div>
			</xsl:when>
			<xsl:otherwise>
				<div class="UBLPostalAddress">
					<div>
						<span class="UBLStreetName">
							<xsl:apply-templates select="cbc:StreetName"/>
						</span>
						<xsl:if test="cbc:AdditionalStreetName !=''">
							<span class="UBLAdditionalStreetName">
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AddressAdditionalStreet']"/>&#160; <xsl:apply-templates select="cbc:AdditionalStreetName"/><br/>
							</span>
						</xsl:if>
					</div>
					<div>
						<xsl:if test="cbc:PostalZone !='' or cbc:CityName !=''">
							<span class="UBLPostalZone">
								<xsl:apply-templates select="cbc:PostalZone"/>&#160;
							</span>
							<span class="UBLCityName">
								<xsl:apply-templates select="cbc:CityName"/>
							</span>
						</xsl:if>
					</div>
					<div>
						<xsl:if test="cac:Country/cbc:IdentificationCode !=''">
							<span>
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AddressCountry']"/>&#160; <xsl:apply-templates select="cac:Country"/>
							</span>
						</xsl:if>
					</div>
					<div>
						<xsl:if test="cbc:CoutntrySubentity !=''">
							<span>
								<xsl:apply-templates select="cbc:CountrySubentity"/><br/>
							</span>
						</xsl:if>
					</div>
				</div>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="cac:AddressLine">
		<span class="UBLLine">
			<xsl:apply-templates select="cbc:Line"/><br/>
		</span>
	</xsl:template>
	<xsl:template match="cac:Country">
		<span class="UBLCountry">
			<xsl:apply-templates select="cbc:IdentificationCode"/>
		</span>
	</xsl:template>
	<xsl:template match="cac:PartyIdentification">
		<xsl:if test="cbc:ID !=''">
			<xsl:if test="cbc:ID != ../cbc:EndpointID">
				<div class="UBLPartyIdentification">
					<xsl:apply-templates select="cbc:ID"/>&#160;(<xsl:value-of select="cbc:ID/@schemeID"/>)
				</div>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<xsl:template match="cac:PartyLegalEntity">
		<div class="UBLPartyLegalEntity">
			<span class="UBLCompanyID">
				<xsl:if test="cbc:CompanyID != ../cac:PartyIdentification/cbc:ID">
					<xsl:apply-templates select="cbc:CompanyID"/>&#160; (<xsl:value-of select="cbc:CompanyID/@schemeID"/>,&#160;<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PartyLegalEntity']"/>)
				</xsl:if>
			</span>
		</div>
	</xsl:template>
	<xsl:template match="cac:PartyTaxScheme">
		<div class="UBLPartyTaxScheme">
			<span class="UBLCompanyID">
				<xsl:apply-templates select="cbc:CompanyID"/>&#160; (<xsl:value-of select="cbc:CompanyID/@schemeID"/>,&#160;<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PartyTaxScheme']"/>)
			</span>
		</div>
	</xsl:template>
	<!--Party template hertil-->

	<!--Leverings template herfra-->
	<xsl:template match="cac:Delivery" mode="header">
		<tr>
			<xsl:if test="cbc:ActualDeliveryDate !='' or cac:RequestedDeliveryPeriod !='' or cbc:LatestDeliveryDate !='' or cbc:LatestDeliveryTime !=''">
				<td>
					<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryTime']"/></b> <br/>
					<xsl:if test="cbc:ActualDeliveryDate !=''">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ActualDeliveryDate']"/>&#160; <xsl:apply-templates select="cbc:ActualDeliveryDate"/><br/>
					</xsl:if>
					<xsl:if test="cac:RequestedDeliveryPeriod !=''">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='RequestedDeliveryPeriod']"/>&#160; <xsl:apply-templates select="cac:RequestedDeliveryPeriod"/><br/>
					</xsl:if>
					<xsl:if test="cbc:LatestDeliveryDate !=''">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='LatestDeliveryDate']"/>&#160; <xsl:apply-templates select="cbc:LatestDeliveryDate"/><br/>
					</xsl:if>
					<xsl:if test="cbc:LatestDeliveryTime !=''">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='LatestDeliveryTime']"/>&#160; <xsl:apply-templates select="cbc:LatestDeliveryTime"/>
					</xsl:if>
				</td>
			</xsl:if>
			<xsl:if test="cac:DeliveryLocation !=''">
				<td>
					<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryLocation']"/></b> <br/>
					<xsl:apply-templates select="cac:DeliveryLocation"/>
				</td>
			</xsl:if>
			<xsl:if test="../cac:DeliveryTerms !=''">
				<td>
					<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryTerms']"/></b> <br/>
					<xsl:apply-templates select="../cac:DeliveryTerms"/>
				</td>
			</xsl:if>
			<xsl:if test="cac:DeliveryParty !=''">
				<td>
					<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryParty']"/></b> <br/>
					<xsl:apply-templates select="cac:DeliveryParty"/>
				</td>
			</xsl:if>
		</tr>
	</xsl:template>

	<xsl:template match="cac:DeliveryTerms">
		<xsl:if test="cbc:ID !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryTermsID']"/>&#160; <xsl:apply-templates select="cbc:ID"/><br/>
		</xsl:if>
		<xsl:if test="cbc:SpecialTerms !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliverySpecialTerms']"/>&#160; <xsl:apply-templates select="cbc:SpecialTerms"/><br/>
		</xsl:if>
		<xsl:if test="cac:DeliveryLocation !=''">
			<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryLocation']"/></b>&#160; <br/><xsl:apply-templates select="cac:DeliveryLocation"/><br/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="cac:DeliveryLocation">
		<xsl:if test="cbc:ID !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryLocationID']"/>&#160; <xsl:apply-templates select="cbc:ID"/><br/>
		</xsl:if>
		<xsl:if test="cbc:Description !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryLocationDescription']"/>&#160; <xsl:apply-templates select="cbc:Description"/><br/>
		</xsl:if>
		<xsl:if test="cbc:Conditions !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryLocationConditions']"/>&#160; <xsl:apply-templates select="cbc:Conditions"/><br/>
		</xsl:if>
		<xsl:if test="cac:Address !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryLocationAddress']"/>&#160; <br/><xsl:apply-templates select="cac:Address"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="cac:Delivery" mode="line">
		<td class="UBLLine">
			<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryAddress']"/></b> <br/>
			<xsl:apply-templates select="cac:DeliveryAddress"/>
			<xsl:if test="cbc:ActualDeliveryDate !=''">
				<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ActualDeliveryDate']"/>&#160;<xsl:apply-templates select="cbc:ActualDeliveryDate"/><br/>
			</xsl:if>
			<xsl:if test="cac:RequestedDeliveryPeriod !=''">
				<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='RequestedDeliveryPeriod']"/>&#160;<xsl:apply-templates select="cac:RequestedDeliveryPeriod"/><br/>
			</xsl:if>
			<xsl:if test="cac:DeliveryParty !=''">
				<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryParty']"/></b><br/>
				<xsl:apply-templates select="cac:DeliveryParty"/>
			</xsl:if>
		</td>
	</xsl:template>
	<!--
	<xsl:template match="cac:DeliveryLocation">
		<xsl:if test="cbc:ID !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryLocationID']"/>&#160;<xsl:apply-templates select="cbc:ID"/><br/>
		</xsl:if>
		<xsl:if test="cbc:Description !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryLocationDescription']"/>&#160;<xsl:apply-templates select="cbc:Description"/><br/>
		</xsl:if>
		<xsl:if test="cbc:Conditions !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryLocationConditions']"/>&#160;<xsl:apply-templates select="cbc:Conditions"/>
		</xsl:if>
	</xsl:template>-->
	<!--Leverings template hertil-->

	<!--Kontakt herfra-->
	<xsl:template match="cac:AccountingSupplierParty/cac:Party" mode="accsupcontact">
		<xsl:apply-templates select="cac:Contact"/>
	</xsl:template>
	<xsl:template match="cac:AccountingCustomerParty/cac:Party" mode="acccuscontact">
		<xsl:apply-templates select="cac:Contact"/>
	</xsl:template>
	<xsl:template match="cac:SellerSupplierParty/cac:Party" mode="selsupcontact">
		<xsl:apply-templates select="cac:Contact"/>
	</xsl:template>
	<xsl:template match="cac:BuyerCustomerParty/cac:Party" mode="buycuscontact">
		<xsl:apply-templates select="cac:Contact"/>
	</xsl:template>
	<xsl:template match="cac:SenderParty" mode="sendercontact">
		<xsl:apply-templates select="cac:Contact"/>
	</xsl:template>
	<xsl:template match="cac:ReceiverParty" mode="receivercontact">
		<xsl:apply-templates select="cac:Contact"/>
	</xsl:template>

	<xsl:template match="cac:Contact">
		<div class="UBLContact">
			<div class="UBLID">
				<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ContactID']"/>&#160; <xsl:apply-templates select="cbc:ID"/>
			</div>
				<xsl:if test="cbc:Name !=''">
					<div class="UBLName">
						<xsl:apply-templates select="cbc:Name"/>
					</div>
				</xsl:if>
			<div>
				<xsl:if test="cbc:Telephone !=''">
					<span class="UBLTelephone">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Telephone']"/>&#160; <xsl:apply-templates select="cbc:Telephone"/>
					</span>
				</xsl:if>
			</div>
			<div>
				<xsl:if test="cbc:Telefax !=''">
					<span class="UBLTelefax">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Telefax']"/>&#160; <xsl:apply-templates select="cbc:Telefax"/>
					</span>
				</xsl:if>
			</div>
			<div>
				<xsl:if test="cbc:ElectronicMail !=''">
					<span class="UBLElectronicMail">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ElectronicMail']"/>&#160; <xsl:apply-templates select="cbc:ElectronicMail"/>
					</span>
				</xsl:if>
			</div>
		</div>
	</xsl:template>
	<!--Kontakt hertil-->

	<!--Fakturalinje herfra-->
		<xsl:template match="cac:InvoiceLine">
			<tr class="UBLInvoiceLine">
				<td>
					<xsl:apply-templates select="cbc:ID"/>
				</td>
				<td class="UBLSellersItemIdentification">
					<xsl:apply-templates select="cac:Item/cac:SellersItemIdentification"/>
				</td>
				<td class="UBLName">
					<xsl:apply-templates select="cac:Item/cbc:Name"/>
				</td>
				<td class="UBLInvoicedQuantity">
					<xsl:apply-templates select="cbc:InvoicedQuantity"/>
				</td>
				<td class="UBLInvoiceQuantityUnit">
					<xsl:apply-templates select="cbc:InvoicedQuantity/@unitCode"/>
				</td>
				<td class="UBLPriceUnit">
					<xsl:apply-templates select="cac:Price"/>  <xsl:apply-templates select="cac:Price/cbc:BaseQuantity"/>&#160;<xsl:apply-templates select="cac:Price/cbc:BaseQuantity/@unitCode"/>
				</td>
				<td class="UBLTax">
					<xsl:choose>
						<xsl:when test="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:ID = 'StandardRated'and count(cac:TaxTotal/cac:TaxSubtotal) = 1">
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCodeVATPercent']"/>
						</xsl:when>
						<xsl:when test="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:ID = 'ZeroRated' and count(cac:TaxTotal/cac:TaxSubtotal) = 1">
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCodeZERORATEDPercent']"/>
						</xsl:when>
						<xsl:when test="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:ID = 'ReverseCharge' and count(cac:TaxTotal/cac:TaxSubtotal) = 1">
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCodeREVERSECHARGE']"/>
						</xsl:when>
					</xsl:choose>
				</td>
				<td class="UBLPriceAllowanceCharge">
					<xsl:choose>
						<xsl:when test="cac:Price/cac:AllowanceCharge/cbc:ChargeIndicator ='true'">
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ChargeIndicatorTrue']"/>:&#160; <xsl:apply-templates select="cac:Price/cac:AllowanceCharge/cbc:Amount"/>&#160;<xsl:apply-templates select="cbc:Amount/@currencyID"/>
						</xsl:when>
						<xsl:when test="cac:Price/cac:AllowanceCharge/cbc:ChargeIndicator ='false'">
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ChargeIndicatorFalse']"/>:&#160; <xsl:apply-templates select="cac:Price/cac:AllowanceCharge/cbc:Amount"/>&#160;<xsl:apply-templates select="cbc:Amount/@currencyID"/>
						</xsl:when>
					</xsl:choose>
				</td>
				<td class="UBLLineExtensionAmount" align="right">
					<xsl:apply-templates select="cbc:LineExtensionAmount"/>&#160;<xsl:apply-templates select="cbc:LineExtensionAmount/@currencyID"/>
				</td>
			</tr>
			<tr>
				<td>&#160;</td>
				<td>&#160;</td>
				<td class="UBLLine" colspan="3">
					<xsl:if test="cbc:FreeOfChargeIndicator ='true'">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='FreeOfChargeIndicatorTrue']"/></b><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:SellersItemIdentification/cbc:ExtendedID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SellersItemIdentificationExt']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:SellersItemIdentification/cbc:ExtendedID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:BuyersItemIdentification/cbc:ID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='BuyersItemIdentification']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:BuyersItemIdentification/cbc:ID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:BuyersItemIdentification/cbc:ExtendedID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='BuyersItemIdentificationExt']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:BuyersItemIdentification/cbc:ExtendedID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:StandardItemIdentification/cbc:ID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='StandardItemIdentification']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:StandardItemIdentification/cbc:ID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:StandardItemIdentification/cbc:ExtendedID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='StandardItemIdentificationExt']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:StandardItemIdentification/cbc:ExtendedID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ItemClassificationCode']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
						<xsl:if test="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listName !=''">
							(<xsl:apply-templates select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listName"/>)
						</xsl:if>
						<br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:CommodityClassification/cbc:CommodityCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='CommodityCode']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:CommodityClassification/cbc:CommodityCode"/><br/>
					</xsl:if>
					<xsl:if test="cac:Price/cbc:PriceTypeCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PriceTypeCode']"/>&#160;</b> <xsl:apply-templates select="cac:Price/cbc:PriceTypeCode"/><br/>
					</xsl:if>
					<xsl:if test="cac:Price/cbc:PriceType !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PriceType']"/>&#160;</b> <xsl:apply-templates select="cac:Price/cbc:PriceType"/><br/>
					</xsl:if>
					<xsl:if test="cac:Price/cbc:OrderableUnitFactorRate !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OrderableUnitFactorRate']"/>&#160;</b> <xsl:apply-templates select="cac:Price/cbc:OrderableUnitFactorRate"/><br/>
					</xsl:if>
					<xsl:if test="cac:Price/cac:ValidityPeriod !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PriceValidityPeriode']"/>&#160;</b> <xsl:apply-templates select="cac:Price/cac:ValidityPeriod"/><br/>
					</xsl:if>
					<xsl:if test="cbc:Note !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Notes']"/>&#160;</b> <xsl:apply-templates select="cbc:Note"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cbc:PackQuantity !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PackQuantity']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cbc:PackQuantity"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cbc:PackSizeNumeric !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PackSizeNumeric']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cbc:PackSizeNumeric"/><br/>
					</xsl:if>
					<xsl:if test="cac:OrderLineReference/cac:OrderReference !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OrderDocumentReference']"/>&#160;</b> <xsl:apply-templates select="cac:OrderLineReference/cac:OrderReference" mode="line"/><br/>
					</xsl:if>
					<xsl:if test="cac:OrderLineReference/cbc:LineID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OrderLineReferenceID']"/>&#160;</b> <xsl:apply-templates select="cac:OrderLineReference/cbc:LineID"/><br/>
					</xsl:if>
					<xsl:if test="cac:OrderLineReference/cbc:LineStatusCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OrderLineStatusCode']"/>&#160;</b> <xsl:apply-templates select="cac:OrderLineReference/cbc:LineStatusCode"/><br/>
					</xsl:if>
					<xsl:if test="cbc:AccountingCost !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AccountingCost']"/>&#160;</b> <xsl:apply-templates select="cbc:AccountingCost"/><br/>
					</xsl:if>
					<xsl:if test="cac:AllowanceCharge !=''">
						<xsl:apply-templates select="cac:AllowanceCharge" mode="line"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:OriginCountry/cbc:IdentificationCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OriginCountry']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:OriginCountry/cbc:IdentificationCode"/><br/>
					</xsl:if>
					<xsl:if test="cac:TaxTotal !=''">
						<xsl:apply-templates select="cac:TaxTotal" mode="line"/><br/>
					</xsl:if>
				</td>
				<xsl:if test="cac:Delivery/cac:DeliveryAddress/cbc:AddressFormatCode !=''">
					<xsl:apply-templates select="cac:Delivery" mode="line"/>
				</xsl:if>
			</tr>
		</xsl:template>
		<xsl:template match="cac:SellersItemIdentification">
			<xsl:apply-templates select="cbc:ID"/>
		</xsl:template>
		<xsl:template match="cac:Price">
			<xsl:apply-templates select="cbc:PriceAmount"/>
		</xsl:template>
		<xsl:template match="cac:Country">
			<span class="UBLCountry">
				<xsl:apply-templates select="cbc:IdentificationCode"/>
			</span>
		</xsl:template>
	<!--Fakturalinje hertil-->

	<!--Kreditnotalinje herfra-->
		<xsl:template match="cac:CreditNoteLine">
			<tr class="UBLCreditNoteLine">
				<td>
					<xsl:apply-templates select="cbc:ID"/>
				</td>
				<td class="UBLSellersItemIdentification">
					<xsl:apply-templates select="cac:Item/cac:SellersItemIdentification"/>
				</td>
				<td class="UBLName">
					<xsl:apply-templates select="cac:Item/cbc:Name"/>
				</td>
				<td class="UBLCreditedQuantity">
					<xsl:apply-templates select="cbc:CreditedQuantity"/>
				</td>
				<td class="UBLInvoiceQuantityUnit">
					<xsl:apply-templates select="cbc:CreditedQuantity/@unitCode"/>
				</td>
				<td class="UBLPriceUnit">
					<xsl:apply-templates select="cac:Price"/>  <xsl:apply-templates select="cac:Price/cbc:BaseQuantity"/>&#160;<xsl:apply-templates select="cac:Price/cbc:BaseQuantity/@unitCode"/>
				</td>
				<td class="UBLTax">
					<xsl:choose>
						<xsl:when test="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:ID = 'StandardRated'and count(cac:TaxTotal/cac:TaxSubtotal) = 1">
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCodeVATPercent']"/>
						</xsl:when>
						<xsl:when test="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:ID = 'ZeroRated' and count(cac:TaxTotal/cac:TaxSubtotal) = 1">
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCodeZERORATEDPercent']"/>
						</xsl:when>
						<xsl:when test="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:ID = 'ReverseCharge' and count(cac:TaxTotal/cac:TaxSubtotal) = 1">
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCodeREVERSECHARGE']"/>
						</xsl:when>
					</xsl:choose>
				</td>
				<td class="UBLLineExtensionAmount" align="right">
					<xsl:apply-templates select="cbc:LineExtensionAmount"/>&#160;<xsl:apply-templates select="cbc:LineExtensionAmount/@currencyID"/>
				</td>
			</tr>
			<tr>
				<td>&#160;</td>
				<td>&#160;</td>
				<td class="UBLLine" colspan="3">
					<xsl:if test="cac:DiscrepancyResponse/cbc:ReferenceID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ReferenceID']"/>&#160;</b>
						<xsl:apply-templates select="cac:DiscrepancyResponse/cbc:ReferenceID"/>&#160;-&#160;
						<xsl:apply-templates select="cac:DiscrepancyResponse/cbc:Description"/><br/>
					</xsl:if>
					<xsl:if test="cac:BillingReference !=''">
						<xsl:apply-templates select="cac:BillingReference"/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:SellersItemIdentification/cbc:ExtendedID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SellersItemIdentificationExt']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:SellersItemIdentification/cbc:ExtendedID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:BuyersItemIdentification/cbc:ID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='BuyersItemIdentification']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:BuyersItemIdentification/cbc:ID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:BuyersItemIdentification/cbc:ExtendedID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='BuyersItemIdentificationExt']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:BuyersItemIdentification/cbc:ExtendedID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:StandardItemIdentification/cbc:ID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='StandardItemIdentification']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:StandardItemIdentification/cbc:ID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:StandardItemIdentification/cbc:ExtendedID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='StandardItemIdentificationExt']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:StandardItemIdentification/cbc:ExtendedID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ItemClassificationCode']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
						<xsl:if test="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listName !=''">
							(<xsl:apply-templates select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listName"/>)
						</xsl:if>
						<br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:CommodityClassification/cbc:CommodityCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='CommodityCode']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:CommodityClassification/cbc:CommodityCode"/><br/>
					</xsl:if>
					<xsl:if test="cac:Price/cbc:PriceTypeCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PriceTypeCode']"/>&#160;</b> <xsl:apply-templates select="cac:Price/cbc:PriceTypeCode"/><br/>
					</xsl:if>
					<xsl:if test="cac:Price/cbc:PriceType !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PriceType']"/>&#160;</b> <xsl:apply-templates select="cac:Price/cbc:PriceType"/><br/>
					</xsl:if>
					<xsl:if test="cac:Price/cbc:OrderableUnitFactorRate !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OrderableUnitFactorRate']"/>&#160;</b> <xsl:apply-templates select="cac:Price/cbc:OrderableUnitFactorRate"/><br/>
					</xsl:if>
					<xsl:if test="cac:Price/cac:ValidityPeriod !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PriceValidityPeriode']"/>&#160;</b> <xsl:apply-templates select="cac:Price/cac:ValidityPeriod"/><br/>
					</xsl:if>
					<xsl:if test="cbc:Note !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Notes']"/>&#160;</b> <xsl:apply-templates select="cbc:Note"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cbc:PackQuantity !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PackQuantity']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cbc:PackQuantity"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cbc:PackSizeNumeric !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PackSizeNumeric']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cbc:PackSizeNumeric"/><br/>
					</xsl:if>
					<xsl:if test="cac:OrderLineReference/cac:OrderReference !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OrderDocumentReference']"/>&#160;</b> <xsl:apply-templates select="cac:OrderLineReference/cac:OrderReference" mode="line"/><br/>
					</xsl:if>
					<xsl:if test="cac:OrderLineReference/cbc:LineID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OrderLineReferenceID']"/>&#160;</b> <xsl:apply-templates select="cac:OrderLineReference/cbc:LineID"/><br/>
					</xsl:if>
					<xsl:if test="cac:OrderLineReference/cbc:LineStatusCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OrderLineStatusCode']"/>&#160;</b> <xsl:apply-templates select="cac:OrderLineReference/cbc:LineStatusCode"/><br/>
					</xsl:if>
					<xsl:if test="cbc:AccountingCost !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AccountingCost']"/>&#160;</b> <xsl:apply-templates select="cbc:AccountingCost"/><br/>
					</xsl:if>
					<xsl:if test="cac:AllowanceCharge !=''">
						<xsl:apply-templates select="cac:AllowanceCharge" mode="line"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:OriginCountry/cbc:IdentificationCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OriginCountry']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:OriginCountry/cbc:IdentificationCode"/><br/>
					</xsl:if>
				</td>
				<xsl:if test="cac:Delivery/cac:DeliveryAddress/cbc:AddressFormatCode !=''">
					<xsl:apply-templates select="cac:Delivery" mode="line"/>
				</xsl:if>
			</tr>
		</xsl:template>
	<!--Kreditnotalinje hetil-->

	<!--Ordrelinje herfra-->
		<xsl:template match="cac:OrderLine/cac:LineItem">
			<tr class="UBLOrderLine">
				<td class="UBLOrderLine">
					<xsl:apply-templates select="cbc:ID"/>
				</td>
				<td class="UBLSellersItemIdentification">
					<xsl:apply-templates select="cac:Item/cac:SellersItemIdentification"/>
				</td>
				<td class="UBLName">
					<xsl:apply-templates select="cac:Item/cbc:Name"/>
				</td>
				<td class="UBLCreditedQuantity">
					<xsl:apply-templates select="cbc:Quantity"/>
				</td>
				<td class="UBLInvoiceQuantityUnit">
					<xsl:apply-templates select="cbc:Quantity/@unitCode"/>
				</td>
				<td class="UBLPriceUnit">
					<xsl:apply-templates select="cac:Price"/>  <xsl:apply-templates select="cac:Price/cbc:BaseQuantity"/>&#160;<xsl:apply-templates select="cac:Price/cbc:BaseQuantity/@unitCode"/>
				</td>
				<td class="UBLLineExtensionAmount" align="right">
					<xsl:apply-templates select="cbc:LineExtensionAmount"/>&#160;<xsl:apply-templates select="cbc:LineExtensionAmount/@currencyID"/>
				</td>
			</tr>
			<tr>
				<td>&#160;</td>
				<td>&#160;</td>
				<td class="UBLLine" colspan="2">
					<xsl:if test="cac:Item/cac:SellersItemIdentification/cbc:ExtendedID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SellersItemIdentificationExt']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:SellersItemIdentification/cbc:ExtendedID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:BuyersItemIdentification/cbc:ID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='BuyersItemIdentification']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:BuyersItemIdentification/cbc:ID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:BuyersItemIdentification/cbc:ExtendedID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='BuyersItemIdentificationExt']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:BuyersItemIdentification/cbc:ExtendedID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:ManufacturersItemIdentification/cbc:ID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ManufacturersItemIdentification']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:ManufacturersItemIdentification/cbc:ID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:ManufacturersItemIdentification/cbc:ExtendedID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ManufacturersItemIdentificationExt']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:ManufacturersItemIdentification/cbc:ExtendedID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:StandardItemIdentification/cbc:ID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='StandardItemIdentification']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:StandardItemIdentification/cbc:ID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:StandardItemIdentification/cbc:ExtendedID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='StandardItemIdentificationExt']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:StandardItemIdentification/cbc:ExtendedID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:CatalogueItemIdentification/cbc:ID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='CatalogueItemIdentification']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:CatalogueItemIdentification/cbc:ID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:CatalogueItemIdentification/cbc:ExtendedID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='CatalogueItemIdentificationExt']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:CatalogueItemIdentification/cbc:ExtendedID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:AdditionalItemIdentification/cbc:ID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AdditionalItemIdentification']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:AdditionalItemIdentification/cbc:ID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:AdditionalItemIdentification/cbc:ExtendedID !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AdditionalItemIdentificationExt']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:AdditionalItemIdentification/cbc:ExtendedID"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cbc:CatalogueIndicator ='true'">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='CatalogueIndicatorTrue']"/></b><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ItemClassificationCode']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
						<xsl:if test="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listName !=''">
							(<xsl:apply-templates select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listName"/>)
						</xsl:if>
						<br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:CommodityClassification/cbc:CommodityCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='CommodityCode']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:CommodityClassification/cbc:CommodityCode"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cbc:Description !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Description']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cbc:Description"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cbc:BrandName !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='BrandName']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cbc:BrandName"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cbc:ModelName !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ModelName']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cbc:ModelName"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:AdditionalItemProperty !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AdditionalItemProperty']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:AdditionalItemProperty/cbc:Name"/>:&#160;<xsl:apply-templates select="cac:Item/cac:AdditionalItemProperty/cbc:Value"/><br/>
					</xsl:if>
					<xsl:if test="cbc:MinimumQuantity !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='MinimumQuantity']"/>&#160;</b> <xsl:apply-templates select="cbc:MinimumQuantity"/><br/>
					</xsl:if>
					<xsl:if test="cbc:MaximumQuantity !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='MaximumQuantity']"/>&#160;</b> <xsl:apply-templates select="cbc:MaximumQuantity"/><br/>
					</xsl:if>
					<xsl:if test="cbc:MinimumBackorderQuantity !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='MinimumBackorderQuantity']"/>&#160;</b> <xsl:apply-templates select="cbc:MinimumBackorderQuantity"/><br/>
					</xsl:if>
					<xsl:if test="cbc:MaximumBackorderQuantity !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='MaximumBackorderQuantity']"/>&#160;</b> <xsl:apply-templates select="cbc:MaximumBackorderQuantity"/><br/>
					</xsl:if>
					<xsl:if test="cbc:InspectionMethodCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='InspectionMethodCode']"/>&#160;</b> <xsl:apply-templates select="cbc:InspectionMethodCode"/><br/>
					</xsl:if>
					<xsl:if test="cbc:PartialDeliveryIndicator ='true'">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PartialDeliveryIndicatorTrue']"/></b><br/>
					</xsl:if>
					<xsl:if test="cbc:BackOrderAllowedIndicator ='true'">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='BackOrderAllowedIndicatorTrue']"/></b><br/>
					</xsl:if>

					<xsl:if test="cac:Item/cbc:AdditionalInformation !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AdditionalInformation']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cbc:AdditionalInformation"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:ItemSpecificationDocumentReference !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DocumentReference']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:ItemSpecificationDocumentReference"/><br/>
					</xsl:if>
					<xsl:if test="../cbc:Note !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Notes']"/>&#160;</b> <xsl:apply-templates select="../cbc:Note"/><br/>
					</xsl:if>
					<xsl:if test="cbc:Note !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Notes']"/>&#160;</b> <xsl:apply-templates select="cbc:Note"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cbc:PackQuantity !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PackQuantity']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cbc:PackQuantity"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cbc:PackSizeNumeric !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PackSizeNumeric']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cbc:PackSizeNumeric"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:OriginCountry/cbc:IdentificationCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OriginCountry']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:OriginCountry/cbc:IdentificationCode"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:OriginAddress !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OriginAddress']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:OriginAddress"/>
					</xsl:if>
					<xsl:if test="cbc:LineStatusCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='OrderLineStatusCode']"/>&#160;</b> <xsl:apply-templates select="cbc:LineStatusCode"/><br/>
					</xsl:if>
					<xsl:if test="cbc:TotalTaxAmount !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TotalTaxAmount']"/>&#160;</b> <xsl:apply-templates select="cbc:TotalTaxAmount"/><br/>
					</xsl:if>
					<xsl:if test="cac:Item/cac:ClassifiedTaxCategory !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ClassifiedTaxCategory']"/>&#160;</b> <xsl:apply-templates select="cac:Item/cac:ClassifiedTaxCategory" mode="supp"/>
					</xsl:if>
					<xsl:if test="cbc:AccountingCost !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AccountingCost']"/>&#160;</b> <xsl:apply-templates select="cbc:AccountingCost"/><br/>
					</xsl:if>
				</td>
				<td class="UBLLine" colspan="3">
					<xsl:if test="cac:DeliveryTerms !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryTerms']"/>&#160;</b><br/>
						<xsl:apply-templates select="cac:DeliveryTerms"/>
					</xsl:if>
					<xsl:if test="cac:Delivery/cac:DeliveryAddress/cbc:AddressFormatCode !=''">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DeliveryAddress']"/></b> <xsl:apply-templates select="cac:Delivery"/><br/>
					</xsl:if>
				</td>
			</tr>
		</xsl:template>
<!--Ordrelinje hertil-->

	<!--Totaler herfra-->
		<!--Faktura-->
		<xsl:template match="cac:LegalMonetaryTotal" mode="LineTotal">
			<tr class="UBLLineExtensionAmount">
				<td bgcolor="#FFFFFF" colspan="6">
					<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='LineExtensionAmountTotal']"/></b>
				</td>
				<td bgcolor="#FFFFFF" align="right">
					<xsl:value-of select="format-number(cbc:LineExtensionAmount, '##0.00')"/>&#160;<xsl:apply-templates select="cbc:LineExtensionAmount/@currencyID"/>
				</td>
			</tr>
		</xsl:template>
		<xsl:template match="cac:LegalMonetaryTotal" mode="Total">
			<tr class="UBLPayableAmount">
				<td bgcolor="#FFFFFF" colspan="6">
					<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PayableAmountInv']"/></b>
				</td>
				<td bgcolor="#FFFFFF" align="right">
					<xsl:value-of select="format-number(cbc:PayableAmount, '##0.00')"/>&#160;<xsl:apply-templates select="cbc:PayableAmount/@currencyID"/>
				</td>
			</tr>
		</xsl:template>

		<!--Faktura og kreditnota, Supplerende oplysninger-->
		<xsl:template match="cac:LegalMonetaryTotal" mode="supp">
		<xsl:if test="cbc:TaxExclusiveAmount !='' or cbc:AllowanceTotalAmount !='' or cbc:ChargeTotalAmount !='' or cbc:PrepaidAmount !='' or cbc:PayableRoundingAmount !=''">
			<br/><b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='LegalMonetaryTotal']"/></b><br/>
			<xsl:if test="cbc:TaxExclusiveAmount !=''">
				<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxExclusiveAmount']"/>&#160;
				<xsl:apply-templates select="cbc:TaxExclusiveAmount"/>&#160;<xsl:apply-templates select="cbc:TaxExclusiveAmount/@currencyID"/>
			</xsl:if>
			<xsl:if test="cbc:AllowanceTotalAmount !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AllowanceTotalAmount']"/>&#160;
				<xsl:apply-templates select="cbc:AllowanceTotalAmount"/>&#160;<xsl:apply-templates select="cbc:AllowanceTotalAmount/@currencyID"/>
			</xsl:if>
			<xsl:if test="cbc:ChargeTotalAmount !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ChargeTotalAmount']"/>&#160;
				<xsl:apply-templates select="cbc:ChargeTotalAmount"/>&#160;<xsl:apply-templates select="cbc:ChargeTotalAmount/@currencyID"/>
			</xsl:if>
			<xsl:if test="cbc:PrepaidAmount !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PrepaidAmount']"/>&#160;
				<xsl:apply-templates select="cbc:PrepaidAmount"/>&#160;<xsl:apply-templates select="cbc:PrepaidAmount/@currencyID"/>
			</xsl:if>
			<xsl:if test="cbc:PayableRoundingAmount !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PayableRoundingAmount']"/>&#160;
				<xsl:apply-templates select="cbc:PayableRoundingAmount"/>&#160;<xsl:apply-templates select="cbc:PayableRoundingAmount/@currencyID"/>
			</xsl:if>
		</xsl:if>
		</xsl:template>

		<!--Kreditnota-->
		<xsl:template match="cac:LegalMonetaryTotal" mode="TotalKreditNota">
			<tr class="UBLPayableAmount">
				<td bgcolor="#FFFFFF" colspan="6">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PayableAmountCN']"/></b>
				</td>
				<td bgcolor="#FFFFFF" align="right">
						<xsl:value-of select="format-number(cbc:PayableAmount, '##0.00')"/>&#160;<xsl:apply-templates select="cbc:PayableAmount/@currencyID"/>
				</td>
			</tr>
		</xsl:template>

		<!--Ordre-->
		<xsl:template match="cac:AnticipatedMonetaryTotal" mode="LineTotal">
			<tr class="UBLLineExtensionAmount">
				<td bgcolor="#FFFFFF" colspan="6">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='LineExtensionAmountTotal']"/></b>
				</td>
				<td bgcolor="#FFFFFF" align="right">
						<xsl:value-of select="format-number(cbc:LineExtensionAmount, '##0.00')"/>&#160;<xsl:apply-templates select="cbc:LineExtensionAmount/@currencyID"/>
				</td>
			</tr>
		</xsl:template>
		<xsl:template match="cac:AnticipatedMonetaryTotal" mode="Total">
			<tr class="UBLPayableAmount">
				<td bgcolor="#FFFFFF" colspan="6">
						<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AnticipatedMonetaryTotalOrd']"/></b>
				</td>
				<td bgcolor="#FFFFFF" align="right">
						<xsl:value-of select="format-number(cbc:PayableAmount, '##0.00')"/>&#160;<xsl:apply-templates select="cbc:PayableAmount/@currencyID"/>
				</td>
			</tr>
		</xsl:template>
	<!--Totaler hertil-->

	<!--AllowanceCharge herfra-->
		<xsl:template match="cac:AllowanceCharge" mode="total">
			<tr>
				<td colspan="6">
					<xsl:choose>
						<xsl:when test="cbc:ChargeIndicator ='true'">
								<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ChargeIndicatorTrue']"/></b>&#160; (<xsl:apply-templates select="cbc:AllowanceChargeReason"/>)&#160;
						</xsl:when>
						<xsl:when test="cbc:ChargeIndicator ='false'">
								<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ChargeIndicatorFalse']"/></b>&#160; (<xsl:apply-templates select="cbc:AllowanceChargeReason"/>)&#160;
						</xsl:when>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="cac:TaxCategory/cbc:ID ='StandardRated'">
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCodeVAT']"/>
						</xsl:when>
						<xsl:when test="cac:TaxCategory/cbc:ID ='ZeroRated'">
								<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCodeZERORATED']"/>
						</xsl:when>
					</xsl:choose>
				</td>
				<td align="right">
						<xsl:value-of select="format-number(cbc:Amount, '##0.00')"/>&#160;<xsl:apply-templates select="cbc:Amount/@currencyID"/>
				</td>
			</tr>
		</xsl:template>

		<xsl:template match="cac:AllowanceCharge" mode="line">
			<xsl:choose>
				<xsl:when test="cbc:ChargeIndicator ='true'">
					<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ChargeIndicatorTrue']"/></b>&#160; (<xsl:apply-templates select="cbc:AllowanceChargeReason"/>)&#160;
				</xsl:when>
				<xsl:when test="cbc:ChargeIndicator ='false'">
					<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ChargeIndicatorFalse']"/></b>&#160; (<xsl:apply-templates select="cbc:AllowanceChargeReason"/>)&#160;
				</xsl:when>
			</xsl:choose>
			<xsl:choose>
				<xsl:when test="cac:TaxCategory/cbc:ID ='StandardRated'">
					<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCodeVAT']"/>
				</xsl:when>
				<xsl:when test="cac:TaxCategory/cbc:ID ='ZeroRated'">
					<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCodeZERORATED']"/>
				</xsl:when>
			</xsl:choose>
			&#160;<xsl:value-of select="format-number(cbc:Amount, '##0.00')"/>&#160;<xsl:apply-templates select="cbc:Amount/@currencyID"/>
		</xsl:template>

		<xsl:template match="cac:AllowanceCharge" mode="supp">
		<xsl:if test="cbc:ID !='' or cbc:MultiplierFactorNumeric !='' or cbc:BaseAmount !='' or cbc:SequenceNumeric !='' or cbc:AccountingCost !=''">
			<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AllowanceChargeSupp']"/></b><br/>
			<xsl:choose>
				<xsl:when test="cbc:ChargeIndicator ='true'">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ChargeIndicatorTrue']"/>&#160; (<xsl:apply-templates select="cbc:AllowanceChargeReason"/>)&#160;
				</xsl:when>
				<xsl:when test="cbc:ChargeIndicator ='false'">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ChargeIndicatorFalse']"/>&#160; (<xsl:apply-templates select="cbc:AllowanceChargeReason"/>)&#160;
				</xsl:when>
			</xsl:choose>
			<xsl:choose>
				<xsl:when test="cac:TaxCategory/cbc:ID ='StandardRated'">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCodeVAT']"/>
				</xsl:when>
				<xsl:when test="cac:TaxCategory/cbc:ID ='ZeroRated'">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCodeZERORATED']"/>
				</xsl:when>
			</xsl:choose>
			<xsl:if test="cbc:ID !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ID']"/>&#160;<xsl:apply-templates select="cbc:ID"/>
			</xsl:if>
			<xsl:if test="cbc:MultiplierFactorNumeric !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='MultiplierFactorNumeric']"/>&#160; <xsl:apply-templates select="cbc:MultiplierFactorNumeric"/>
			</xsl:if>
			<xsl:if test="cbc:BaseAmount !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='BaseAmount']"/>&#160; <xsl:apply-templates select="cbc:BaseAmount"/>&#160;<xsl:apply-templates select="cbc:BaseAmount/@currencyID"/>
			</xsl:if>
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Amount']"/>&#160; <xsl:value-of select="format-number(cbc:Amount, '##0.00')"/>&#160;<xsl:apply-templates select="cbc:Amount/@currencyID"/>
			<xsl:if test="cbc:SequenceNumeric !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SequenceNumeric']"/>&#160; <xsl:apply-templates select="cbc:SequenceNumeric"/>
			</xsl:if>
			<xsl:if test="cbc:AccountingCost !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='AccountingCost']"/>&#160; <xsl:apply-templates select="cbc:AccountingCost"/>
			</xsl:if>
		</xsl:if>
		</xsl:template>
	<!--AllowanceCharge hertil-->

<!--TaxTotal herfra-->
		<xsl:template match="cac:TaxTotal" mode="afgift">
			<xsl:apply-templates select="cac:TaxSubtotal" mode="afgift"/>
		</xsl:template>

		<xsl:template match="cac:TaxSubtotal" mode="afgift">
			<xsl:variable name="momspct" select="cac:TaxCategory/cbc:Percent"/>
			<!-- Div. afgifter-->
			<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode">
			<tr>
				<td bgcolor="#FFFFFF" colspan="6">
					<b>
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxCategoryIDNotVAT']"/>&#160;
						(<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxCategoryID2']"/>&#160; <xsl:value-of select="cac:TaxCategory/cbc:ID"/>,&#160;
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxSchemeID']"/>&#160; <xsl:value-of select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>,&#160;
						<xsl:value-of select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>&#160;-&#160;
						<xsl:value-of select="format-number($momspct, '##0.00')"/>%)
					</b>
				</td>
				<td bgcolor="#FFFFFF" align="right">
					<xsl:variable name="tot4" select="cbc:TaxAmount"/>
					<xsl:value-of select="format-number($tot4, '##0.00')"/>&#160;<xsl:apply-templates select="cbc:TaxAmount/@currencyID"/>
				</td>
			</tr>
			</xsl:if>
		</xsl:template>

		<xsl:template match="cac:TaxTotal" mode="moms">
			<xsl:apply-templates select="cac:TaxSubtotal" mode="momsfri"/>
			<xsl:apply-templates select="cac:TaxSubtotal" mode="momspligtig"/>
			<xsl:apply-templates select="cac:TaxSubtotal" mode="momstotal"/>
		</xsl:template>

		<xsl:template match="cac:TaxSubtotal" mode="momstotal">
				<xsl:variable name="nuller">
					<xsl:choose>
						<xsl:when test="cbc:TaxAmount = ''">nul</xsl:when>
						<xsl:when test="cbc:TaxAmount = '0'">nul</xsl:when>
						<xsl:when test="cbc:TaxAmount = '0.0'">nul</xsl:when>
						<xsl:when test="cbc:TaxAmount = '0.00'">nul</xsl:when>
						<xsl:when test="cbc:TaxAmount = '0.000'">nul</xsl:when>
						<xsl:otherwise>ejnul</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="momspct" select="cac:TaxCategory/cbc:Percent"/>
				<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID ='63'">
					<xsl:if test="$nuller = 'ejnul'">
						<tr>
							<td bgcolor="#FFFFFF" colspan="6">
								<!-- Totalmoms -->
								<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxCategoryIDVAT']"/>&#160; (<xsl:value-of select="format-number($momspct, '##0.00')"/>%)</b>
							</td>
							<td bgcolor="#FFFFFF" align="right">
								<xsl:variable name="tot4" select="cbc:TaxAmount"/>
								<xsl:value-of select="format-number($tot4, '##0.00')"/>&#160;<xsl:apply-templates select="cbc:TaxAmount/@currencyID"/>
							</td>
						</tr>
					</xsl:if>
				</xsl:if>
		</xsl:template>
		<xsl:template match="cac:TaxSubtotal" mode="momsfri">
				<!-- Momsfri andel -->
				<xsl:if test="cac:TaxCategory/cbc:ID = 'ZeroRated' and cac:TaxCategory/cac:TaxScheme/cbc:ID ='63'">
					<tr>
						<td bgcolor="#FFFFFF" colspan="6">
								<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCodeZERORATEDTotal']"/></b>
						</td>
						<td bgcolor="#FFFFFF" align="right">
								<xsl:variable name="tot3" select="cbc:TaxableAmount"/>
								<xsl:value-of select="format-number($tot3, '##0.00')"/>&#160;<xsl:apply-templates select="cbc:TaxableAmount/@currencyID"/>
						</td>
					</tr>
				</xsl:if>
				<!-- Reverse Charge -->
				<xsl:if test="cac:TaxCategory/cbc:ID = 'ReverseCharge' and cac:TaxCategory/cac:TaxScheme/cbc:ID ='63'">
					<tr>
						<td bgcolor="#FFFFFF" colspan="6">
								<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCodeZERORATEDTotal2']"/></b>
						</td>
						<td bgcolor="#FFFFFF" align="right">
								<xsl:variable name="tot3" select="cbc:TaxableAmount"/>
								<xsl:value-of select="format-number($tot3, '##0.00')"/>&#160;<xsl:apply-templates select="cbc:TaxableAmount/@currencyID"/>
						</td>
					</tr>
				</xsl:if>
		</xsl:template>
		<xsl:template match="cac:TaxSubtotal" mode="momspligtig">
				<xsl:if test="cac:TaxCategory/cbc:ID = 'StandardRated' and cac:TaxCategory/cac:TaxScheme/cbc:ID ='63'">
					<tr>
						<td bgcolor="#FFFFFF" colspan="6">
								<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCodeVATTotal']"/></b>
						</td>
						<td bgcolor="#FFFFFF" align="right">
								<xsl:variable name="tot6" select="cbc:TaxableAmount"/>
								<xsl:value-of select="format-number($tot6, '##0.00')"/>&#160;<xsl:apply-templates select="cbc:TaxableAmount/@currencyID"/>
						</td>
					</tr>
				</xsl:if>
		</xsl:template>

		<!--Supplerende Moms oplysninger-->
		<xsl:template match="cac:TaxTotal" mode="supp">
			<xsl:if test="cbc:RoundingAmount !='' or cac:TaxSubtotal/cbc:CalculationSequenceNumeric !=''  or cac:TaxSubtotal/cbc:TransactionCurrencyTaxAmount !='' or cac:TaxSubtotal/cbc:BaseUnitMeasure !='' or cac:TaxSubtotal/cbc:PerUnitAmount !=''or cac:TaxSubtotal/cac:TaxCategory/cbc:BaseUnitMeasure !='' or cac:TaxSubtotal/l/cac:TaxCategory/cbc:PerUnitAmount !=''">
			<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTotalSupp']"/></b><br/>
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxAmount']"/>&#160;<xsl:apply-templates select="cbc:TaxAmount"/>&#160;<xsl:apply-templates select="cbc:TaxAmount/@currencyID"/>
			<xsl:if test="cbc:RoundingAmount !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxRoundingAmount']"/>&#160; <xsl:apply-templates select="cbc:RoundingAmount"/>&#160;<xsl:apply-templates select="cbc:RoundingAmount/@currencyID"/>
			</xsl:if>
			<xsl:apply-templates select="cac:TaxSubtotal" mode="supp"/>
			</xsl:if>
		</xsl:template>

		<xsl:template match="cac:TaxSubtotal" mode="supp">
			<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxableAmount']"/>&#160; <xsl:apply-templates select="cbc:TaxableAmount"/>&#160;<xsl:apply-templates select="cbc:TaxableAmount/@currencyID"/>
			<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxAmountTotal']"/>&#160; <xsl:apply-templates select="cbc:TaxAmount"/>&#160;<xsl:apply-templates select="cbc:TaxAmount/@currencyID"/>
			<xsl:if test="cbc:CalculationSequenceNumeric !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxCalculationSequenceNumeric']"/>&#160; <xsl:apply-templates select="cbc:CalculationSequenceNumeric"/>
			</xsl:if>
			<xsl:if test="cbc:TransactionCurrencyTaxAmount !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TransactionCurrencyTaxAmount']"/>&#160; <xsl:apply-templates select="cbc:TransactionCurrencyTaxAmount"/>&#160;<xsl:apply-templates select="cbc:TransactionCurrencyTaxAmount/@currencyID"/>
			</xsl:if>
			<xsl:apply-templates select="cac:TaxCategory" mode="supp"/>
		</xsl:template>

		<xsl:template match="cac:TaxCategory | cac:ClassifiedTaxCategory" mode="supp">
			<xsl:if test="cbc:ID !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxCategoryID']"/>&#160; <xsl:apply-templates select="cbc:ID"/>
			</xsl:if>
			<xsl:if test="cbc:BaseUnitMeasure !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='BaseUnitMeasure']"/>&#160; <xsl:apply-templates select="cbc:BaseUnitMeasure"/>&#160;<xsl:apply-templates select="cbc:BaseUnitMeasure/@unitCode"/>
			</xsl:if>
			<xsl:if test="cbc:PerUnitAmount !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PerUnitAmount']"/>&#160; <xsl:apply-templates select="cbc:PerUnitAmount"/>&#160;<xsl:apply-templates select="cbc:PerUnitAmount/@currencyID"/>
			</xsl:if>
			<xsl:apply-templates select="cac:TaxScheme" mode="supp"/>
		</xsl:template>

		<xsl:template match="cac:TaxScheme" mode="supp">
			<xsl:if test="cbc:ID !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxSchemeID']"/>&#160; <xsl:apply-templates select="cbc:ID"/>
			</xsl:if>
			<xsl:if test="cbc:Name !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Name']"/>&#160; <xsl:apply-templates select="cbc:Name"/>
			</xsl:if>
			<xsl:if test="cbc:TaxTypeCode !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCode']"/>&#160; <xsl:apply-templates select="cbc:TaxTypeCode"/>
			</xsl:if>
			<xsl:if test="cbc:CurrencyCode !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='CurrencyCode']"/>&#160; <xsl:apply-templates select="cbc:CurrencyCode"/>
			</xsl:if>
			<xsl:apply-templates select="cac:JurisdictionRegionAddress"/>
		</xsl:template>

		<!--Supplerende Moms oplysninger til linjen-->
		<xsl:template match="cac:TaxTotal" mode="line">
			<xsl:if test="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID !='63'">
			<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTotalSupp']"/></b><br/>
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxAmountTotal']"/>&#160;<xsl:apply-templates select="cbc:TaxAmount"/>&#160;<xsl:apply-templates select="cbc:TaxAmount/@currencyID"/>
			<xsl:if test="cbc:RoundingAmount !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxRoundingAmount']"/>&#160; <xsl:apply-templates select="cbc:RoundingAmount"/>&#160;<xsl:apply-templates select="cbc:RoundingAmount/@currencyID"/>
			</xsl:if>
			<xsl:apply-templates select="cac:TaxSubtotal" mode="line"/>
			</xsl:if>
		</xsl:template>

		<xsl:template match="cac:TaxSubtotal" mode="line">
			<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxableAmount']"/>&#160; <xsl:apply-templates select="cbc:TaxableAmount"/>&#160;<xsl:apply-templates select="cbc:TaxableAmount/@currencyID"/>
			<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxAmount']"/>&#160; <xsl:apply-templates select="cbc:TaxAmount"/>&#160;<xsl:apply-templates select="cbc:TaxAmount/@currencyID"/>
			<xsl:if test="cbc:CalculationSequenceNumeric !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxCalculationSequenceNumeric']"/>&#160; <xsl:apply-templates select="cbc:CalculationSequenceNumeric"/>
			</xsl:if>
			<xsl:if test="cbc:TransactionCurrencyTaxAmount !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TransactionCurrencyTaxAmount']"/>&#160; <xsl:apply-templates select="cbc:TransactionCurrencyTaxAmount"/>&#160;<xsl:apply-templates select="cbc:TransactionCurrencyTaxAmount/@currencyID"/>
			</xsl:if>
			<xsl:apply-templates select="cac:TaxCategory" mode="line"/>
		</xsl:template>

		<xsl:template match="cac:TaxCategory" mode="line">
			<xsl:if test="cbc:ID !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxCategoryID']"/>&#160; <xsl:apply-templates select="cbc:ID"/>
			</xsl:if>
			<xsl:if test="cbc:BaseUnitMeasure !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='BaseUnitMeasure']"/>&#160; <xsl:apply-templates select="cbc:BaseUnitMeasure"/>&#160;<xsl:apply-templates select="cbc:BaseUnitMeasure/@unitCode"/>
			</xsl:if>
			<xsl:if test="cbc:PerUnitAmount !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PerUnitAmount']"/>&#160; <xsl:apply-templates select="cbc:PerUnitAmount"/>&#160;<xsl:apply-templates select="cbc:PerUnitAmount/@currencyID"/>
			</xsl:if>
			<xsl:apply-templates select="cac:TaxScheme" mode="line"/>
		</xsl:template>

		<xsl:template match="cac:TaxScheme" mode="line">
			<xsl:if test="cbc:ID !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxSchemeID']"/>&#160; <xsl:apply-templates select="cbc:ID"/>
			</xsl:if>
			<xsl:if test="cbc:Name !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Name']"/>&#160; <xsl:apply-templates select="cbc:Name"/>
			</xsl:if>
			<xsl:if test="cbc:TaxTypeCode !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TaxTypeCode']"/>&#160; <xsl:apply-templates select="cbc:TaxTypeCode"/>
			</xsl:if>
			<xsl:if test="cbc:CurrencyCode !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='CurrencyCode']"/>&#160; <xsl:apply-templates select="cbc:CurrencyCode"/>
			</xsl:if>
			<xsl:apply-templates select="cac:JurisdictionRegionAddress"/>
		</xsl:template>
<!--TaxTotal hertil-->

<!--PaymentMeans herfra-->
	<xsl:template match="cac:PaymentMeans">
	<table>
		<tr>
			<td>
				<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PaymentMeans']"/></b>
			</td>
		</tr>
		<xsl:if test="count(/n1:Invoice/cac:PaymentMeans/cbc:ID) &gt; 1">
			<tr>
				<td>
					<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PaymentMeansID']"/>&#160; <xsl:apply-templates select="cbc:ID"/>
				</td>
			</tr>
		</xsl:if>
		<tr>
			<td>
				<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PaymentDueDate']"/>&#160; <xsl:apply-templates select="cbc:PaymentDueDate"/>
			</td>
		</tr>
		<tr>
			<xsl:choose>
				<xsl:when test="cbc:PaymentMeansCode = '42'">
					<td>
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PaymentMeansCode42']"/>&#160;
						<xsl:if test="cbc:PaymentChannelCode='DK:BANK' or cbc:PaymentChannelCode='IBAN'">
							(<xsl:apply-templates select="cbc:PaymentChannelCode"/>):&#160;
						</xsl:if>
						<xsl:if test="cac:PayeeFinancialAccount/cac:FinancialInstitutionBranch/cac:FinancialInstitution/cbc:Name!=''">
							<xsl:apply-templates select="cac:PayeeFinancialAccount/cac:FinancialInstitutionBranch/cac:FinancialInstitution/cbc:Name"/>&#160;
						</xsl:if>
						<xsl:apply-templates select="cac:PayeeFinancialAccount/cac:FinancialInstitutionBranch/cbc:ID"/>&#160;
						<xsl:apply-templates select="cac:PayeeFinancialAccount/cbc:ID"/>
					</td>
				</xsl:when>
				<xsl:when test="cbc:PaymentMeansCode = '31'">
					<td>
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PaymentMeansCode30']"/>&#160;
						<xsl:if test="cbc:PaymentChannelCode='IBAN'">
								(<xsl:apply-templates select="cbc:PaymentChannelCode"/>):&#160;
						</xsl:if>
						<br/>
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='FinancialInstitutionID']"/>&#160; <xsl:apply-templates select="cac:PayeeFinancialAccount/cac:FinancialInstitutionBranch/cac:FinancialInstitution/cbc:ID"/>&#160;
						<xsl:if test="cac:PayeeFinancialAccount/cac:FinancialInstitutionBranch/cac:FinancialInstitution/cbc:Name !=''">
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='FinancialInstitutionName']"/>&#160; <xsl:apply-templates select="cac:PayeeFinancialAccount/cac:FinancialInstitutionBranch/cac:FinancialInstitution/cbc:Name"/>&#160;
						</xsl:if>
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PayeeFinancialAccountID']"/>&#160; <xsl:apply-templates select="cac:PayeeFinancialAccount/cbc:ID"/>&#160;
					</td>
				</xsl:when>
				<xsl:when test="cbc:PaymentMeansCode = '50'">
					<xsl:if test="cbc:PaymentID = '01' or cbc:PaymentID = '04' or cbc:PaymentID = '15'">
						<td>
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PaymentMeansCode50']"/>&#160;&gt;
							<xsl:apply-templates select="cbc:PaymentID"/>&#160;
							<xsl:apply-templates select="cbc:InstructionID"/>&#160;
							+<xsl:apply-templates select="cac:PayeeFinancialAccount/cbc:ID"/>&lt;
						</td>
					</xsl:if>
				</xsl:when>
				<xsl:when test="cbc:PaymentMeansCode = '93'">
					<xsl:if test="cbc:PaymentID = '71' or cbc:PaymentID = '73' or cbc:PaymentID = '75'">
						<td>
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PaymentMeansCode93']"/>&#160;&gt;
							<xsl:apply-templates select="cbc:PaymentID"/>&#160;
							<xsl:apply-templates select="cbc:InstructionID"/>&#160;
							+<xsl:apply-templates select="cac:CreditAccount/cbc:AccountID"/>&lt;
						</td>
					</xsl:if>
				</xsl:when>
				<xsl:when test="cbc:PaymentMeansCode = '49'">
					<td>
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PaymentMeansCode49']"/>&#160; <xsl:apply-templates select="cbc:InstructionID"/>
					</td>
				</xsl:when>
				<xsl:when test="cbc:PaymentMeansCode = '97'">
					<td>
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PaymentMeansCodeZZZ']"/>&#160;
					</td>
				</xsl:when>
				<xsl:otherwise>
					<td>
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PaymentMeansCodeX']"/>
					</td>
				</xsl:otherwise>
			</xsl:choose>
		</tr>
		<xsl:choose>
			<xsl:when test="cbc:PaymentMeansCode='31' or cbc:PaymentMeansCode='42'">
				<xsl:if test="cac:PayeeFinancialAccount/cbc:PaymentNote !=''">
					<tr>
						<td>
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PaymentNote']"/>&#160;&#160; <xsl:apply-templates select="cac:PayeeFinancialAccount/cbc:PaymentNote"/>
						</td>
					</tr>
				</xsl:if>
			</xsl:when>
			<xsl:when test="cbc:PaymentID='01' or cbc:PaymentID='73' or cbc:PaymentID='75'">
				<xsl:if test="cbc:InstructionNote !=''">
					<tr>
						<td>
							<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='InstructionNote']"/>&#160;&#160; <xsl:apply-templates select="cbc:InstructionNote"/>
						</td>
					</tr>
				</xsl:if>
			</xsl:when>
		</xsl:choose>
		<xsl:if test="cac:PayerFinancialAccount !='' or cac:PayeeFinancialAccount !=''">

		</xsl:if>
		</table>
	</xsl:template>
	<!--PaymentMeans template hertil-->

<!-- Betalingsbetingelser herfra-->
	<xsl:template match="cac:PaymentTerms">
	<table>
		<xsl:if test="cbc:ID !=''">
			<tr>
				<td>
					<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PaymentTerms']"/></b>
				</td>
			</tr>
			<tr>
				<td bgcolor="#FFFFFF">
					<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PaymentTermsID']"/>&#160; <xsl:apply-templates select="cbc:ID"/>
				</td>
			</tr>
			<tr>
				<td bgcolor="#FFFFFF">
					<xsl:if test="count(/n1:Invoice/cac:PaymentTerms/cbc:PaymentMeansID) &gt; 1">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PaymentMeansID']"/>&#160; <xsl:apply-templates select="cbc:PaymentMeansID"/>
					</xsl:if>
				</td>
			</tr>
			<xsl:if test="cbc:PrepaidPaymentReferenceID !=''">
				<tr>
					<td bgcolor="#FFFFFF">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PrepaidPaymentReferenceID']"/>&#160; <xsl:apply-templates select="cbc:PrepaidPaymentReferenceID"/>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="cbc:Note !=''">
				<tr>
					<td bgcolor="#FFFFFF">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Notes']"/>&#160;<xsl:apply-templates select="cbc:Note"/>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="cbc:ReferenceEventCode !=''">
				<tr>
					<td bgcolor="#FFFFFF">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ReferenceEventCode']"/>&#160; <xsl:apply-templates select="cbc:ReferenceEventCode"/>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="cac:SettlementPeriod/cbc:EndDate !=''">
				<tr>
					<td bgcolor="#FFFFFF">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SettlementPeriodEndDate']"/>&#160; <xsl:apply-templates select="cac:SettlementPeriod/cbc:EndDate"/>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="cbc:SettlementDiscountPercent !=''">
				<tr>
					<td bgcolor="#FFFFFF">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SettlementDiscountPercent']"/>&#160; <xsl:apply-templates select="cbc:SettlementDiscountPercent"/>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="cac:PenaltyPeriod/cbc:StartDate !=''">
				<tr>
					<td bgcolor="#FFFFFF">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PenaltyPeriodStartDate']"/>&#160; <xsl:apply-templates select="cac:PenaltyPeriod/cbc:StartDate"/>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="cbc:PenaltySurchargePercent !=''">
				<tr>
					<td bgcolor="#FFFFFF">
						<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PenaltySurchargePercent']"/>&#160; <xsl:apply-templates select="cbc:PenaltySurchargePercent"/>
					</td>
				</tr>
			</xsl:if>
		</xsl:if>
	</table>
	</xsl:template>

	<xsl:template match="cac:PrepaidPayment">
		<xsl:if test="cbc:ID !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PrepaidPaymentID']"/>&#160; <xsl:apply-templates select="cbc:ID"/><br/>
		</xsl:if>
		<xsl:if test="cbc:PaidAmount !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PrepaidPaidAmount']"/>&#160; <xsl:apply-templates select="cbc:PaidAmount"/>&#160;<xsl:apply-templates select="cbc:PaidAmount/@currencyID"/><br/>
		</xsl:if>
		<xsl:if test="cbc:ReceivedDate !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PrepaidReceivedDate']"/>&#160; <xsl:apply-templates select="cbc:ReceivedDate"/><br/>
		</xsl:if>
		<xsl:if test="cbc:PaidDate !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PrepaidPaidDate']"/>&#160; <xsl:apply-templates select="cbc:PaidDate"/><br/>
		</xsl:if>
		<xsl:if test="cbc:PaidTime !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PrepaidPaidTime']"/>&#160; <xsl:apply-templates select="cbc:PaidTime"/><br/>
		</xsl:if>
		<xsl:if test="cbc:InstructionID !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PrepaidInstructionID']"/>&#160; <xsl:apply-templates select="cbc:InstructionID"/>
		</xsl:if>
	</xsl:template>
<!--Betalingsbetingelser hertil-->

<!--Referencer herfra-->
	<xsl:template match="cac:OrderReference" mode="header">
		<td>
			<xsl:apply-templates select="cbc:ID"/>
		</td>
		<td>
			<xsl:if test="cbc:UUID !=''">
				<xsl:apply-templates select="cbc:UUID"/>
			</xsl:if>
		</td>
		<td>
			<xsl:if test="cbc:IssueDate !=''">
				<xsl:apply-templates select="cbc:IssueDate"/>
			</xsl:if>
		</td>
	</xsl:template>

	<xsl:template match="cac:OrderReference" mode="line">
		<xsl:apply-templates select="cbc:ID"/>
		<xsl:if test="cbc:IssueDate !=''">
			&#160;<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='IssueDate']"/>&#160; <xsl:apply-templates select="cbc:IssueDate"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="cac:OrderReference" mode="reference">
		<xsl:if test="cac:DocumentReference !=''">
			<xsl:apply-templates select="cac:DocumentReference"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="cac:DocumentReference | cac:ContractDocumentReference | cac:AdditionalDocumentReference | cac:QuotationDocumentReference | cac:InvoiceDocumentReference | cac:SelfBilledInvoiceDocumentReference | cac:CreditNoteDocumentReference | cac:ReminderDocumentReference | cac:ItemSpecificationDocumentReference">
			<xsl:if test="cbc:ID !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ID']"/>&#160; <xsl:apply-templates select="cbc:ID"/>
			</xsl:if>
			<xsl:if test="cbc:UUID !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='UUID']"/>&#160; <xsl:apply-templates select="cbc:UUID"/>
			</xsl:if>
			<xsl:if test="cbc:IssueDate !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='IssueDate']"/>&#160; <xsl:apply-templates select="cbc:IssueDate"/>
			</xsl:if>
			<xsl:if test="cbc:DocumentType !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DocumentType']"/>&#160; <xsl:apply-templates select="cbc:DocumentType"/>
			</xsl:if>
			<xsl:if test="cbc:DocumentTypeCode !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DocumentTypeCode']"/>&#160; <xsl:apply-templates select="cbc:DocumentTypeCode"/>
			</xsl:if>
			<xsl:if test="cbc:XPath !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='XPath']"/>&#160; <xsl:apply-templates select="cbc:XPath"/>
			</xsl:if>
			<xsl:if test="cac:Attachment !=''">
				<xsl:apply-templates select="cac:Attachment"/>
			</xsl:if>
	</xsl:template>
	<xsl:template match="cac:OriginalDocumentReference">
		<xsl:apply-templates select="cac:Attachment"/>
	</xsl:template>

	<xsl:template match="cac:Attachment | cac:DigitalSignatureAttachment">
		<xsl:if test="cbc:EmbeddedDocumentBinaryObject !=''">
			<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='EmbeddedDocumentBinaryObject']"/>&#160; <xsl:apply-templates select="cbc:EmbeddedDocumentBinaryObject"/>
		</xsl:if>
		<xsl:if test="cac:ExternalReference !=''">
			<xsl:apply-templates select="cac:ExternalReference"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="cac:ExternalReference">
		<xsl:if test="cbc:URI !=''">
			<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='URI']"/>&#160; <xsl:apply-templates select="cbc:URI"/>
		</xsl:if>
		<xsl:if test="cbc:DocumentHash !=''">
			<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='DocumentHash']"/>&#160; <xsl:apply-templates select="cbc:DocumentHash"/>
		</xsl:if>
		<xsl:if test="cbc:ExpiryDate !=''">
			<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ExpiryDate']"/>&#160; <xsl:apply-templates select="cbc:ExpiryDate"/>
		</xsl:if>
		<xsl:if test="cbc:ExpiryTime !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ExpiryTime']"/>&#160; <xsl:apply-templates select="cbc:ExpiryTime"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="cac:Contract">
		<span>
			<xsl:if test="cbc:ID !=''">
				<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ContractID']"/>&#160; <xsl:apply-templates select="cbc:ID"/>,&#160;
			</xsl:if>
			<xsl:if test="cbc:IssueDate !=''">
				<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ContractIssueDate']"/>&#160; <xsl:apply-templates select="cbc:IssueDate"/>, &#160;
			</xsl:if>
			<xsl:if test="cbc:ContractTypeCode !=''">
				<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ContractTypeCode']"/>&#160; <xsl:apply-templates select="cbc:ContractTypeCode"/>,&#160;
			</xsl:if>
			<xsl:if test="cbc:ContractType !=''">
				<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ContractType']"/>&#160; <xsl:apply-templates select="cbc:ContractType"/>,&#160;
			</xsl:if>
			<xsl:if test="cac:ContractDocumentReference !=''">
				<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ContractDocumentReferenceID']"/>&#160; <xsl:apply-templates select="cac:ContractDocumentReference"/>
			</xsl:if>
		</span>
	</xsl:template>

	<xsl:template match="cac:BillingReference">
		<xsl:if test="cac:InvoiceDocumentReference !=''">
			<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='InvoiceDocumentReference']"/></b>&#160; <xsl:apply-templates select="cac:InvoiceDocumentReference"/><br/>
		</xsl:if>
		<xsl:if test="cac:SelfBilledInvoiceDocumentReference !=''">
			<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SelfBilledInvoiceDocumentReference']"/></b>&#160; <xsl:apply-templates select="cac:SelfBilledInvoiceDocumentReference"/><br/>
		</xsl:if>
		<xsl:if test="cac:CreditNoteDocumentReference !=''">
			<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='CreditNoteDocumentReference']"/></b>&#160; <xsl:apply-templates select="cac:CreditNoteDocumentReference"/><br/>
		</xsl:if>
		<xsl:if test="cac:ReminderDocumentReference !=''">
			<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ReminderDocumentReference']"/></b>&#160; <xsl:apply-templates select="cac:ReminderDocumentReference"/><br/>
		</xsl:if>
		<xsl:if test="cac:BillingReferenceLine !=''">
			<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='BillingReferenceLine']"/></b>&#160; <xsl:apply-templates select="cac:BillingReferenceLine"/><br/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="cac:BillingReferenceLine">
		<xsl:if test="cbc:ID !=''">
			<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ID']"/>&#160; <xsl:apply-templates select="cbc:ID"/><br/>
		</xsl:if>
		<xsl:if test="cbc:Amount !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Amount']"/>&#160; <xsl:apply-templates select="cbc:Amount"/><br/>
		</xsl:if>
		<xsl:if test="cac:AllowanceCharge !=''">
			<xsl:apply-templates select="cac:AllowanceCharge" mode="line"/>
		</xsl:if>
	</xsl:template>
	<!--Referencer hertil-->

	<!--ExchangeRates herfra-->
	<xsl:template match="cac:TaxExchangeRate | cac:PricingExchangeRate | cac:PaymentExchangeRate | cac:PaymentAlternativeExchangeRate">
		<div>
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SourceCurrencyCode']"/>&#160; <xsl:apply-templates select="cbc:SourceCurrencyCode"/>
			<xsl:if test="cbc:SourceCurrencyBaseRate !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SourceCurrencyBaseRate']"/>&#160; <xsl:apply-templates select="cbc:SourceCurrencyBaseRate"/>
			</xsl:if>
			<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TargetCurrencyCode']"/>&#160; <xsl:apply-templates select="cbc:TargetCurrencyCode"/>
			<xsl:if test="cbc:TargetCurrencyBaseRate !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='TargetCurrencyBaseRate']"/>&#160; <xsl:apply-templates select="cbc:TargetCurrencyBaseRate"/>
			</xsl:if>
			<xsl:if test="cbc:ExchangeMarketID !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ExchangeMarketID']"/>&#160; <xsl:apply-templates select="cbc:ExchangeMarketID"/>
			</xsl:if>
			<xsl:if test="cbc:CalculationRate !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='CalculationRate']"/>&#160; <xsl:apply-templates select="cbc:CalculationRate"/>
			</xsl:if>
			<xsl:if test="cbc:MathematicOperatorCode !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='MathematicOperatorCode']"/>&#160; <xsl:apply-templates select="cbc:MathematicOperatorCode"/>
			</xsl:if>
			<xsl:if test="cbc:Date !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='IssueDate']"/>&#160; <xsl:apply-templates select="cbc:Date"/>
			</xsl:if>
			<xsl:if test="cbc:ForeignExchangeContract !=''">
				<br/><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='ContractDocumentReferenceID']"/>&#160; <xsl:apply-templates select="cbc:ForeignExchangeContract"/>
			</xsl:if>
		</div>
	</xsl:template>
	<!--ExchangeRates hertil-->

	<!--Periodeangivelser herfra-->
	<xsl:template match="cac:Delivery/cac:RequestedDeliveryPeriod | cac:InvoicePeriod | cac:RequestedDeliveryPeriod | cac:ValidityPeriod">
		<xsl:if test="cbc:StartDate !=''">
			<xsl:if test="cbc:EndDate !='' and cbc:EndDate != cbc:StartDate">
				<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PeriodStartDate']"/>&#160;
			</xsl:if>
			<xsl:apply-templates select="cbc:StartDate"/>,&#160;
		</xsl:if>
		<xsl:if test="cbc:EndDate !='' and cbc:EndDate != cbc:StartDate">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PeriodEndDate']"/>&#160; <xsl:apply-templates select="cbc:EndDate"/>,&#160;
		</xsl:if>
		<xsl:if test="cbc:Description !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='PeriodDescription']"/>&#160; <xsl:apply-templates select="cbc:Description"/>
		</xsl:if>
	</xsl:template>
	<!--Periodeangivelser hertil-->


	<!--Signatur herfra-->
	<xsl:template match="cac:Signature">
		<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='Signature']"/></b><br/>
		<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SignatureID']"/>&#160; <xsl:apply-templates select="cbc:ID"/><br/>
		<xsl:if test="cbc:Note !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SignatureNote']"/>&#160; <xsl:apply-templates select="cbc:Note"/><br/>
		</xsl:if>
		<xsl:if test="cbc:ValidationDate !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SignatureValidationDate']"/>&#160; <xsl:apply-templates select="cbc:ValidationDate"/><br/>
		</xsl:if>
		<xsl:if test="cbc:ValidationTime !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SignatureValidationTime']"/>&#160; <xsl:apply-templates select="cbc:ValidationTime"/><br/>
		</xsl:if>
		<xsl:if test="cbc:ValidatorID !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SignatureValidationID']"/>&#160; <xsl:apply-templates select="cbc:ValidatorID"/><br/>
		</xsl:if>
		<xsl:if test="cbc:CanonicalizationMethod !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SignatureCanonicalizationMethod']"/>&#160; <xsl:apply-templates select="cbc:CanonicalizationMethod"/><br/>
		</xsl:if>
		<xsl:if test="cbc:SignatureMethod !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SignatureMethod']"/>&#160; <xsl:apply-templates select="cbc:SignatureMethod"/><br/>
		</xsl:if>
		<b><xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SignatureParty']"/></b>&#160; <xsl:apply-templates select="cac:SignatoryParty"/>
		<xsl:if test="cac:DigitalSignatureAttachment !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SignatureAttachment']"/>&#160; <xsl:apply-templates select="cac:DigitalSignatureAttachment"/><br/>
		</xsl:if>
		<xsl:if test="cac:OriginalDocumentReference !=''">
			<xsl:value-of select="$moduleDoc/module/document-merge/g-funcs/g[@name='SignatureOriginalDocumentReference']"/>&#160; <xsl:apply-templates select="cac:OriginalDocumentReference"/><br/>
		</xsl:if>
	</xsl:template>
	<!--Signatur hertil-->

	</xsl:stylesheet>
