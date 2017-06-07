<?xml version="1.0" encoding="US-ASCII"?>
<?xml-stylesheet type="text/xsl" href="../xslstyle/xslstyle-docbook.xsl"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.CraneSoftwrights.com/ns/xslstyle"
                xmlns:in="urn:oasis:names:specification:ubl:schema:xsd:Order-2"
                xmlns:cbc=
         "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
                xmlns:cac=
     "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
                xmlns:c="urn:X-Crane"
                exclude-result-prefixes="xs c in"
                version="1.0">

<xs:doc filename="Invinet-Order2Invoice.xsl" vocabulary="DocBook"
   info="$Id: Invinet-Order2Invoice.xsl,v 1.11 2016/10/18 15:20:10 admin Exp $">
  <xs:title>Convert a UBL Order into a UBL Invoice</xs:title>
  <para>
    Copyright (C) Invinet
  </para>
  <para>
    Based on the <literal>OrderToInvoice-20161010-0940z.RTF</literal>
    specification, this will create an Order document from an Invoice document.
  </para>
  <para>
    This stylesheet is explicitly handling all top-level elements so as not
    to lose track of unspecified handling of constructs.
  </para>
</xs:doc>

<!--========================================================================-->
<xs:doc>
  <xs:title>Invocation parameters, input file</xs:title>
  <para>
    The input file (<literal>-s</literal>) is the schema-validated UBL Order
    document:
  </para>
  <programlisting>
saxon655 -o myInvoice.xml myOrder.xml Invinet-Order2Invoice.xsl
         ID=OUTPUT-INVOICE-cbc:ID-VALUE
         IssueDate=YYYY-MM-DD
         {optional parameters}</programlisting>
</xs:doc>

<xs:param ignore-ns='yes'>
  <para>
    REQUIRED: The invoice number of the output document.
  </para>
</xs:param>
<xsl:param name="ID"/>

<xs:param ignore-ns='yes'>
  <para>
    REQUIRED: The issue date for the resulting invoice.
  </para>
</xs:param>
<xsl:param name="IssueDate"/>

<xs:param ignore-ns='yes'>
  <para>
    The customization identifier (use empty string to copy from input)
  </para>
</xs:param>
<xsl:param name="CustomizationID"/>

<xs:param ignore-ns='yes'>
  <para>
    The profile identifier (use empty string to copy from input)
  </para>
</xs:param>
<xsl:param name="ProfileID"/>

<xs:output>
  <para>Indent the results for development</para>
</xs:output>
<xsl:output indent="yes" omit-xml-declaration="no"/>

<!--========================================================================-->
<xs:doc>
  <xs:title>Main document handling</xs:title>
</xs:doc>

<xs:template>
  <para>
    The input is unexpected or embedded
  </para>
</xs:template>
<xsl:template match="/*">
  <xsl:choose>
    <xsl:when test="(.//in:Order)[1]">
      <!--the order is embedded in the outer document-->
      <xsl:for-each select="(.//in:Order)[1]">
        <xsl:call-template name="c:start"/>
      </xsl:for-each>
    </xsl:when>
    <xsl:otherwise>
      <!--must be zero or more than one Order, can only work on exactly one-->
      <xsl:message terminate="yes">
        <xsl:text>The input document is unexpected. Expecting: {</xsl:text>
        <xsl:value-of select="document('')/*/namespace::in"/>
        <xsl:text>}:Order but found {</xsl:text>
     <xsl:value-of select="concat(namespace-uri(document('')/*),'}',name(.))"/>
      </xsl:message>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xs:template>
  <para>
    This is the building of the result invoice.
  </para>
</xs:template>
<xsl:template match="/in:Order" name="c:start" priority="1">
  <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2">
    <!--the spec doesn't say about others, but probably should be copied-->
    <xsl:apply-templates mode="c:noNS" select="cbc:UBLVersionID"/><!--001-->
    <cbc:CustomizationID schemeID="PEPPOL">urn:www.cenbii.eu:transaction:biitrns010:ver2.0:extended:urn:www.peppol.eu:bis:peppol4a:ver2.0</cbc:CustomizationID>
    <cbc:ProfileID>urn:www.cenbii.eu:profile:bii04:ver2.0</cbc:ProfileID>
    <!--special handling for the customization identifier-->
    <xsl:if test="string($CustomizationID)">
      <xsl:choose>
        <xsl:when test="normalize-space($CustomizationID)">
          <cbc:CustomizationID>
            <xsl:value-of select="$CustomizationID"/>
          </cbc:CustomizationID>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="c:noNS" select="cbc:CustomizationID"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <!--special handling for the profile identifier-->
    <xsl:if test="string($ProfileID)">
      <xsl:choose>
        <xsl:when test="normalize-space($ProfileID)">
          <cbc:ProfileID>
            <xsl:value-of select="$ProfileID"/>
          </cbc:ProfileID>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="c:noNS" select="cbc:ProfileID"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <!--use the identifier supplied at invocation time-->
    <cbc:ID><xsl:value-of select="$ID"/></cbc:ID>
    <cbc:IssueDate>
      <xsl:value-of select="$IssueDate"/>
    </cbc:IssueDate>
    <cbc:InvoiceTypeCode listID="UNCL1001">380</cbc:InvoiceTypeCode>
    <xsl:apply-templates mode="c:noNS" select="cbc:Note"/><!--003-->
    <xsl:apply-templates mode="c:noNS"
                         select="cbc:DocumentCurrencyCode"/><!--004-->
    <xsl:apply-templates mode="c:noNS" select="cbc:AccountingCost"/><!--005-->
    <xsl:apply-templates mode="c:noNS"
               select="cbc:AdditionalDocumentReference"/><!--006,007,008,009-->
    <cac:OrderReference>
      <xsl:apply-templates mode="c:noNS" select="cbc:ID"/><!--002-->
    </cac:OrderReference>
    <xsl:for-each select="cac:Contract">
      <cac:ContractDocumentReference>
        <xsl:apply-templates mode="c:noNS" select="cbc:ID"/><!--010-->
        <xsl:for-each select="cbc:ContractType"><!--011-->
          <cbc:DocumentTypeType>
            <xsl:apply-templates mode="c:noNS" select="@*"/>
<xsl:apply-templates mode="c:noNS" select="node()"/>
          </cbc:DocumentTypeType>
        </xsl:for-each>
      </cac:ContractDocumentReference>
    </xsl:for-each>
    <cac:AccountingSupplierParty>
      <xsl:apply-templates mode="c:noNS"
                           select="cac:SellerSupplierParty/*"/>
                     <!--030,031,032,033,034,035,036,037,038,039,040,041,042-->
    </cac:AccountingSupplierParty>
    <cac:AccountingCustomerParty>
      <xsl:apply-templates mode="c:noNS"
                           select="cac:BuyerCustomerParty/*"/>
 <!--012,013,014,015,016,017,018,019,020,021,022,023,024,025,026,027,028,029-->
    </cac:AccountingCustomerParty>
    <xsl:apply-templates mode="c:noNS"
                      select="cac:Delivery"/><!--043,044,045,046,047,048,049-->
    <xsl:apply-templates mode="c:noNS" select="cac:PaymentTerms"/><!--050-->
    <xsl:apply-templates mode="c:noNS"
                         select="cac:AllowanceCharge"/><!--051,052,053-->
    <xsl:apply-templates mode="c:noNS" select="cac:TaxTotal"/><!--054-->
    <cac:LegalMonetaryTotal>
      <xsl:apply-templates mode="c:noNS"
select="cac:AnticipatedMonetaryTotal/*"/><!--055,056,057,058,059,060,061,062-->
    </cac:LegalMonetaryTotal>
    <xsl:for-each select="cac:OrderLine">
      <cac:InvoiceLine>
        <xsl:for-each select="cac:LineItem">
          <xsl:apply-templates mode="c:noNS" select="cbc:ID"/>
<xsl:apply-templates mode="c:noNS" select="
                               ../cbc:Note"/><!--064,063-->
          <xsl:for-each select="cbc:Quantity"><!--065-->
            <cbc:InvoicedQuantity>
              <xsl:apply-templates mode="c:noNS" select="@*"/>
<xsl:apply-templates mode="c:noNS" select="node()"/>
            </cbc:InvoicedQuantity>
          </xsl:for-each>
          <xsl:apply-templates mode="c:noNS"
                               select="cbc:LineExtensionAmount"/><!--066-->
          <xsl:apply-templates mode="c:noNS"
                               select="cbc:AccountingCost"/><!--068-->
          <xsl:for-each
       select="cac:Delivery/cac:RequestedDeliveryPeriod/cbc:EndDate"><!--069-->
            <cac:Delivery>
              <cbc:ActualDeliveryDate>
                <xsl:apply-templates mode="c:noNS" select="@*"/>
<xsl:apply-templates mode="c:noNS" select="node()"/>
              </cbc:ActualDeliveryDate>
            </cac:Delivery>
          </xsl:for-each>
          <xsl:for-each select="cbc:TotalTaxAmount"><!--067-->
            <cac:TaxTotal>
              <cbc:TaxAmount>
                <xsl:apply-templates mode="c:noNS" select="@*"/>
<xsl:apply-templates mode="c:noNS" select="node()"/>
              </cbc:TaxAmount>
            </cac:TaxTotal>
          </xsl:for-each>
          <xsl:apply-templates mode="c:noNS"
              select="cac:Item"/><!--075,076,077,078,079,080,081,082,083,084-->
          <xsl:apply-templates mode="c:noNS"
                               select="cac:Price"/><!--070,071,072,073,074-->
        </xsl:for-each>
      </cac:InvoiceLine>
    </xsl:for-each>
  </Invoice>
</xsl:template>

<!--========================================================================-->
<xs:doc>
  <xs:title>Support facilities</xs:title>
</xs:doc>

<xs:template>
  <para>
    Expose the XPath address of the current element.
  </para>
</xs:template>
<xsl:template name="c:xpath">
  <xsl:for-each select="ancestor-or-self::*">
    <xsl:text/>/<xsl:value-of select="name(.)"/>
    <xsl:if test="position()>1">
      <xsl:text/>[<xsl:number/>]<xsl:text/>
    </xsl:if>
  </xsl:for-each>
</xsl:template>

<xs:template>
  <para>
    Copy all elements and their attributes without copying namespaces
  </para>
</xs:template>
<xsl:template match="*" mode="c:noNS">
  <xsl:element name="{name(.)}" namespace="{namespace-uri(.)}">
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates select="node()" mode="c:noNS"/>
  </xsl:element>
</xsl:template>

<xs:template>
  <para>
    Copy all non-elements without copying namespaces (which is redundant, but
    for processing parallels, this template rule exists)
  </para>
</xs:template>
<xsl:template match="text()|comment()|processing-instruction()|@*"
              mode="c:noNS">
  <xsl:copy-of select="."/>
</xsl:template>

<xs:template>
  <para>
    Assume that a white-space-only text node must be indentation, so remove
    it since it is being automatically indented.
  </para>
</xs:template>
<xsl:template match="text()[not(normalize-space(.))]"
              mode="c:noNS"/>

</xsl:stylesheet>
