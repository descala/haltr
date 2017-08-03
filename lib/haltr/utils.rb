module Haltr
  module Utils

    require "rexml/document"
    class << self

      def compress(string)
        return nil if string.nil?
        buf = ActiveSupport::Gzip.compress(string)
        Base64::encode64(buf).chomp
      end

      def decompress(string)
        return nil if string.nil?
        begin
          buf = Base64::decode64(string)
          ActiveSupport::Gzip.decompress(buf)
        rescue
          string
        end
      end

      # retrieve xpath from document
      # if xpath is an array, concatenates its values
      def get_xpath(doc,xpath)
        val = doc.xpath(*xpath)
        val.blank? ? nil : val.collect {|v| v.text.to_s.strip }.join(" ")
      end

      def xpaths_for(format, root_element='Invoice')
        xpaths = {}.with_indifferent_access
        if format =~ /facturae/
          xpaths[:invoice_number]     = "//Invoices/Invoice/InvoiceHeader/InvoiceNumber"
          xpaths[:invoice_series]     = "//Invoices/Invoice/InvoiceHeader/InvoiceSeriesCode"
          xpaths[:amend_of]           = "//Invoices/Invoice/InvoiceHeader/Corrective/InvoiceNumber"
          xpaths[:amend_of_serie]     = "//Invoices/Invoice/InvoiceHeader/Corrective/InvoiceSeriesCode"
          xpaths[:amend_type]         = "//Invoices/Invoice/InvoiceHeader/Corrective/CorrectionMethod"
          xpaths[:amend_reason]       = "//Invoices/Invoice/InvoiceHeader/Corrective/ReasonCode"
          xpaths[:invoice_date]       = "//Invoices/Invoice/InvoiceIssueData/IssueDate"
          xpaths[:tax_point_date]     = "//Invoices/Invoice/InvoiceIssueData/OperationDate"
          xpaths[:invoicing_period_start] = "//Invoices/Invoice/InvoiceIssueData/InvoicingPeriod/StartDate"
          xpaths[:invoicing_period_end]   = "//Invoices/Invoice/InvoiceIssueData/InvoicingPeriod/EndDate"
          xpaths[:invoice_total]      = "//Invoices/Invoice/InvoiceTotals/InvoiceTotal"
          xpaths[:invoice_totalgross] = "//Invoices/Invoice/InvoiceTotals/TotalGrossAmount"
          xpaths[:invoice_import]     = "//Invoices/Invoice/InvoiceTotals/TotalGrossAmountBeforeTaxes"
          xpaths[:discount_amount]    = "//Invoices/Invoice/InvoiceTotals/TotalGeneralDiscounts"
          xpaths[:discount_percent]   = "//Invoices/Invoice/InvoiceTotals/GeneralDiscounts/Discount/DiscountRate"
          xpaths[:discount_text]      = "//Invoices/Invoice/InvoiceTotals/GeneralDiscounts/Discount/DiscountReason"
          xpaths[:payments_on_account]= "//Invoices/Invoice/InvoiceTotals/TotalPaymentsOnAccount"
          xpaths[:amounts_withheld_r] = "//Invoices/Invoice/InvoiceTotals/AmountsWithheld/WithholdingAmount"
          xpaths[:amounts_withheld]   = "//Invoices/Invoice/InvoiceTotals/AmountsWithheld/WithholdingAmount"
          xpaths[:invoice_due_date]   = "//Invoices/Invoice/PaymentDetails/Installment/InstallmentDueDate"
          xpaths[:seller_taxcode]     = "//Parties/SellerParty/TaxIdentification/TaxIdentificationNumber"
          xpaths[:party_id]           = "//Parties/SellerParty/PartyIdentification"
          xpaths[:seller_name]        = "//Parties/SellerParty/LegalEntity/CorporateName"
          xpaths[:seller_name2]       = [ "//Parties/SellerParty/Individual/Name",
                                          "//Parties/SellerParty/Individual/FirstSurname",
                                          "//Parties/SellerParty/Individual/SecondSurname" ]
          xpaths[:seller_address]     = "//Parties/SellerParty/*/*/Address"
          xpaths[:seller_province]    = "//Parties/SellerParty/*/*/Province"
          xpaths[:seller_countrycode] = "//Parties/SellerParty/*/*/CountryCode"
          xpaths[:seller_website]     = "//Parties/SellerParty/*/ContactDetails/WebAddress"
          xpaths[:seller_email]       = "//Parties/SellerParty/LegalEntity/ContactDetails/ElectronicMail"
          xpaths[:seller_cp_city]     = [ "//Parties/SellerParty/*/*/PostCode",
                                          "//Parties/SellerParty/*/*/Town" ]
          xpaths[:seller_cp_city2]    = "//Parties/SellerParty/*/*/PostCodeAndTown"
          xpaths[:seller_cp]          = "//Parties/SellerParty/*/*/PostCode"
          xpaths[:buyer_taxcode]      = "//Parties/BuyerParty/TaxIdentification/TaxIdentificationNumber"
          xpaths[:buyer_name]         = "//Parties/BuyerParty/LegalEntity/CorporateName"
          xpaths[:buyer_name2]        = [ "//Parties/BuyerParty/Individual/Name",
                                          "//Parties/BuyerParty/Individual/FirstSurname",
                                          "//Parties/BuyerParty/Individual/SecondSurname" ]
          xpaths[:buyer_address]      = "//Parties/BuyerParty/*/*/Address"
          xpaths[:buyer_province]     = "//Parties/BuyerParty/*/*/Province"
          xpaths[:buyer_countrycode]  = "//Parties/BuyerParty/*/*/CountryCode"
          xpaths[:buyer_website]      = "//Parties/BuyerParty/*/ContactDetails/WebAddress"
          xpaths[:buyer_email]        = "//Parties/BuyerParty/*/ContactDetails/ElectronicMail"
          xpaths[:buyer_cp_city]      = [ "//Parties/BuyerParty/*/*/PostCode",
                                          "//Parties/BuyerParty/*/*/Town" ]
          xpaths[:buyer_cp_city2]     = "//Parties/BuyerParty/*/*/PostCodeAndTown"
          xpaths[:buyer_cp]           = "//Parties/BuyerParty/*/*/PostCode"
          xpaths[:currency]           = "//FileHeader/Batch/InvoiceCurrencyCode"
          xpaths[:exchange_rate]      = "//FileHeader/Batch/ExchangeRateDetails/ExchangeRate"
          xpaths[:exchange_date]      = "//FileHeader/Batch/ExchangeRateDetails/ExchangeDate"
          xpaths[:attachments]        = "//Invoices/Invoice/AdditionalData/RelatedDocuments/Attachment"
          # relative to Attachment
          xpaths[:attach_compression_algorithm] = "AttachmentCompressionAlgorithm"
          xpaths[:attach_format]                = "AttachmentFormat"
          xpaths[:attach_encoding]              = "AttachmentEncoding"
          xpaths[:attach_description]           = "AttachmentDescription"
          xpaths[:attach_data]                  = "AttachmentData"

          xpaths[:extra_info]         = "//Invoices/Invoice/AdditionalData/InvoiceAdditionalInformation"
          xpaths[:charge]             = "//Invoices/Invoice/InvoiceTotals/GeneralSurcharges/Charge/ChargeAmount"
          xpaths[:charge_reason]      = "//Invoices/Invoice/InvoiceTotals/GeneralSurcharges/Charge/ChargeReason"
          xpaths[:accounting_cost]    = "//Parties/BuyerParty/LegalEntity/ContactDetails/ContactPersons"

          xpaths[:to_be_debited]      = "//Invoices/Invoice/PaymentDetails/Installment/AccountToBeDebited"
          xpaths[:to_be_credited]     = "//Invoices/Invoice/PaymentDetails/Installment/AccountToBeCredited"
          xpaths[:payment_method]     = "//Invoices/Invoice/PaymentDetails/Installment/PaymentMeans"
          xpaths[:payment_method_text] = "//Invoices/Invoice/PaymentDetails/Installment/CollectionAdditionalInformation"
          # relative to AccountToBe*
          xpaths[:bank_account]       = "*/AccountNumber"
          xpaths[:iban]               = "*/IBAN"
          xpaths[:bic]                = "*/BIC"

          xpaths[:glob_irpf]          = "//Invoices/Invoice/TaxesWithheld/Tax/TaxRate"
          xpaths[:invoice_lines]      = "//Invoices/Invoice/Items/InvoiceLine"
          # relative to invoice_lines
          xpaths[:i_transaction_ref]  = "IssuerTransactionReference"
          xpaths[:r_contract_reference] = "ReceiverContractReference"
          xpaths[:line_quantity]      = "Quantity"
          xpaths[:line_description]   = "ItemDescription"
          xpaths[:line_price]         = "UnitPriceWithoutTax"
          xpaths[:line_unit]          = "UnitOfMeasure"
          xpaths[:line_taxes]         = ["TaxesOutputs/Tax","TaxesWithheld/Tax"]
          xpaths[:line_notes]         = "AdditionalLineItemInformation"
          xpaths[:line_code]          = "ArticleCode"
          xpaths[:line_discounts]     = "DiscountsAndRebates/*"
          xpaths[:line_charges]       = "Charges/*"
          xpaths[:file_reference]     = "FileReference"
          xpaths[:sequence_number]    = "SequenceNumber"
          xpaths[:tax_event_code]     = "SpecialTaxableEvent/SpecialTaxableEventCode"
          xpaths[:tax_event_reason]   = "SpecialTaxableEvent/SpecialTaxableEventReason"

          xpaths[:delivery_notes]     = "DeliveryNotesReferences/DeliveryNote"
          # relative to invoice_lines/delivery_notes_references/delivery_note
          xpaths[:delivery_note_num]  = "DeliveryNoteNumber"

          xpaths[:ponumber]           = "ReceiverTransactionReference"
          # relative to invoice_lines/discounts
          xpaths[:line_discount_amount]  = "DiscountAmount"
          xpaths[:line_discount_percent] = "DiscountRate"
          xpaths[:line_discount_text]    = "DiscountReason"
          # relative to invoice_lines/charges
          xpaths[:line_charge]        = "ChargeAmount"
          xpaths[:line_charge_reason] = "ChargeReason"
          # relative to invoice_lines/taxes
          xpaths[:tax_id]             = "TaxTypeCode"
          xpaths[:tax_percent]        = "TaxRate"
          xpaths[:tax_surcharge]      = "EquivalenceSurcharge"

          xpaths[:dir3s]              = "//Parties/BuyerParty/AdministrativeCentres/AdministrativeCentre"
          # relative to AdministrativeCentre
          xpaths[:dir3_code]          = "CentreCode"
          xpaths[:dir3_role]          = "RoleTypeCode"
          xpaths[:dir3_name]          = "Name"
          xpaths[:dir3_desc]          = "CentreDescription"
          xpaths[:dir3_address]       = "AddressInSpain/Address"
          xpaths[:dir3_postcode]      = "AddressInSpain/PostCode"
          xpaths[:dir3_town]          = "AddressInSpain/Town"
          xpaths[:dir3_province]      = "AddressInSpain/Province"
          xpaths[:dir3_country]       = "AddressInSpain/CountryCode"

          xpaths[:fa_person_type]     = "//FileHeader/FactoringAssignmentData/Assignee/TaxIdentification/PersonTypeCode"
          xpaths[:fa_residence_type]  = "//FileHeader/FactoringAssignmentData/Assignee/TaxIdentification/ResidenceTypeCode"
          xpaths[:fa_taxcode]         = "//FileHeader/FactoringAssignmentData/Assignee/TaxIdentification/TaxIdentificationNumber"
          xpaths[:fa_name]            = "//FileHeader/FactoringAssignmentData/Assignee/LegalEntity/CorporateName"
          xpaths[:fa_address]         = "//FileHeader/FactoringAssignmentData/Assignee/LegalEntity/AddressInSpain/Address"
          xpaths[:fa_postcode]        = "//FileHeader/FactoringAssignmentData/Assignee/LegalEntity/AddressInSpain/PostCode"
          xpaths[:fa_town]            = "//FileHeader/FactoringAssignmentData/Assignee/LegalEntity/AddressInSpain/Town"
          xpaths[:fa_province]        = "//FileHeader/FactoringAssignmentData/Assignee/LegalEntity/AddressInSpain/Province"
          xpaths[:fa_country]         = "//FileHeader/FactoringAssignmentData/Assignee/LegalEntity/AddressInSpain/CountryCode"
          xpaths[:fa_info]            = "//FileHeader/FactoringAssignmentData/Assignee/LegalEntity/ContactDetails/AdditionalContactDetails"
          xpaths[:fa_duedate]         = "//FileHeader/FactoringAssignmentData/PaymentDetails/Installment/InstallmentDueDate"
          xpaths[:fa_import]          = "//FileHeader/FactoringAssignmentData/PaymentDetails/Installment/InstallmentAmount"
          xpaths[:fa_payment_method]  = "//FileHeader/FactoringAssignmentData/PaymentDetails/Installment/PaymentMeans"
          xpaths[:fa_iban]            = "//FileHeader/FactoringAssignmentData/PaymentDetails/Installment/*/IBAN"
          xpaths[:fa_bank_code]       = "//FileHeader/FactoringAssignmentData/PaymentDetails/Installment/*/BankCode"
          xpaths[:fa_clauses]         = "//FileHeader/FactoringAssignmentData/FactoringAssignmentClauses"

          xpaths[:legal_literals]     = "//Invoices/Invoice/LegalLiterals/LegalReference"

        elsif format =~ /ubl/
          xpaths[:invoice_number]     = "/xmlns:#{root_element}/cbc:ID"
          xpaths[:invoice_date]       = "/xmlns:#{root_element}/cbc:IssueDate"
          xpaths[:extra_info]         = "/xmlns:#{root_element}/cbc:Note"
          xpaths[:invoice_date]       = "/xmlns:#{root_element}/cbc:IssueDate"
          xpaths[:tax_point_date]     = "/xmlns:#{root_element}/cbc:TaxPointDate"
          xpaths[:invoice_total]      = "/xmlns:#{root_element}/cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount"
          xpaths[:invoice_import]     = "/xmlns:#{root_element}/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount"
          xpaths[:payment_method]     = "/xmlns:#{root_element}/cac:PaymentMeans/cbc:PaymentMeansCode"
          xpaths[:invoice_due_date]   = "/xmlns:#{root_element}/cac:PaymentMeans/cbc:PaymentDueDate"
          xpaths[:seller_taxcode]     = "/xmlns:#{root_element}/cac:AccountingSupplierParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID"
          xpaths[:seller_taxcode2]    = "/xmlns:#{root_element}/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID"
          xpaths[:seller_taxcode3]    = "/xmlns:#{root_element}/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID"
          xpaths[:seller_name]        = "/xmlns:#{root_element}/cac:AccountingSupplierParty/cac:Party/cac:PartyName/cbc:Name"
          xpaths[:seller_name2]       = nil
          xpaths[:seller_address]     = [ "/xmlns:#{root_element}/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:StreetName",
                                          "/xmlns:#{root_element}/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:BuildingNumber" ] 
          xpaths[:seller_province]    = "/xmlns:#{root_element}/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:CountrySubentity"
          xpaths[:seller_countrycode] = "/xmlns:#{root_element}/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode"
          xpaths[:seller_website]     = "/xmlns:#{root_element}/cac:AccountingSupplierParty/cac:Party/cbc:WebsiteURI"
          xpaths[:seller_email]       = "/xmlns:#{root_element}/cac:AccountingSupplierParty/cac:Party/cac:Contact/cbc:ElectronicMail"
          xpaths[:seller_cp_city]     = [ "/xmlns:#{root_element}/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:PostalZone",
                                          "/xmlns:#{root_element}/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:CityName" ]
          xpaths[:seller_cp_city2]    = nil
          xpaths[:buyer_taxcode]      = "/xmlns:#{root_element}/cac:AccountingCustomerParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID"
          xpaths[:buyer_taxcode_id]   = "/xmlns:#{root_element}/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"
          xpaths[:buyer_endpoint_id]  = "/xmlns:#{root_element}/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID"
          xpaths[:buyer_name]         = "/xmlns:#{root_element}/cac:AccountingCustomerParty/cac:Party/cac:PartyName/cbc:Name"
          xpaths[:buyer_name2]        = nil
          xpaths[:buyer_address]      = [ "/xmlns:#{root_element}/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:StreetName",
                                          "/xmlns:#{root_element}/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:BuildingNumber" ] 
          xpaths[:buyer_province]     = "/xmlns:#{root_element}/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:CountrySubentity"
          xpaths[:buyer_countrycode]  = "/xmlns:#{root_element}/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode"
          xpaths[:buyer_website]      = "/xmlns:#{root_element}/cac:AccountingCustomerParty/cac:Party/cbc:WebsiteURI"
          xpaths[:buyer_email]        = "/xmlns:#{root_element}/cac:AccountingCustomerParty/cac:Party/cac:Contact/cbc:ElectronicMail"
          xpaths[:buyer_cp_city]      = [ "/xmlns:#{root_element}/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:PostalZone",
                                          "/xmlns:#{root_element}/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:CityName" ]
          xpaths[:buyer_cp_city2]     = nil
          xpaths[:currency]           = "/xmlns:#{root_element}/cbc:DocumentCurrencyCode"

          xpaths[:global_taxes]       = ["/xmlns:#{root_element}/cac:TaxTotal/cac:TaxSubtotal",
                                         "/xmlns:#{root_element}/cac:WithholdingTaxTotal/cac:TaxSubtotal"]
          # relative to global_taxes
          xpaths[:gtax_category]      = "cac:TaxCategory/cbc:ID"
          xpaths[:gtax_percent]       = "cac:TaxCategory/cbc:Percent"
          xpaths[:gtax_name]          = "cac:TaxCategory/cac:TaxScheme/cbc:ID"

          xpaths[:invoice_lines]      = "//cac:#{root_element}Line"
          # relative to invoice_lines
          xpaths[:i_transaction_ref]  = "IssuerTransactionReference" # todo
          xpaths[:r_contract_reference] = "ReceiverContractReference" # todo
          xpaths[:line_quantity]      = "cbc:InvoicedQuantity"
          xpaths[:line_description]   = ["cac:Item/cbc:Name", "cac:Item/cbc:Description"]
          xpaths[:line_price]         = "cac:Price/cbc:PriceAmount"
          xpaths[:line_unit]          = "cbc:InvoicedQuantity/@unitCode"
          xpaths[:line_taxes]         = ["cac:Item/cac:ClassifiedTaxCategory"]
          xpaths[:line_notes]         = ["cbc:Note","cac:Item/cac:SellersItemIdentification/cbc:ID"]
          xpaths[:line_code]          = "cac:Item/cac:StandardItemIdentification/cbc:ID"
          xpaths[:line_discounts]     = "cac:AllowanceCharges[/cbc:ChargeIndicator='false']/*"
          xpaths[:line_charges]       = "cac:AllowanceCharges[/cbc:ChargeIndicator='true']/*"
          xpaths[:file_reference]     = "FileReference" # todo
          xpaths[:sequence_number]    = "SequenceNumber" # todo
          xpaths[:tax_event_code]     = "SpecialTaxableEvent/SpecialTaxableEventCode" # todo

          xpaths[:tax_event_reason]   = "SpecialTaxableEvent/SpecialTaxableEventReason" # todo


          xpaths[:delivery_notes]     = "DeliveryNotesReferences/DeliveryNote" # todo
          # relative to invoice_lines/delivery_notes_references/delivery_note
          xpaths[:delivery_note_num]  = "DeliveryNoteNumber" # todo

          xpaths[:ponumber]           = "/xmlns:#{root_element}/cac:OrderReference/cbc:ID"
          xpaths[:contract_number]    = "/xmlns:#{root_element}/cac:ContractDocumentReference/cbc:ID"
          # relative to invoice_lines/discounts
          xpaths[:line_discount_percent] = "cbc:MultiplierFactorNumeric"
          xpaths[:line_discount_text]    = "cbc:AllowanceChargeReason"
          # relative to invoice_lines/charges
          xpaths[:line_charge]        = "cbc:Amount"
          xpaths[:line_charge_reason] = "cbc:AllowanceChargeReason"
          # relative to invoice_lines/taxes
          xpaths[:tax_name]           = "cac:TaxScheme/cbc:ID"
          xpaths[:tax_category]       = "cbc:ID"

          xpaths[:attachments] = "//cac:AdditionalDocumentReference"
          # relative to attachment
          xpaths[:attach_format]      = "cac:Attachment/cbc:EmbeddedDocumentBinaryObject/@mimeCode"
          xpaths[:attach_encoding]    = "cac:Attachment/cbc:EmbeddedDocumentBinaryObject/@encodingCode"
          xpaths[:attach_description] = "cbc:DocumentType"
          xpaths[:attach_data]        = "cac:Attachment/cbc:EmbeddedDocumentBinaryObject"

          xpaths[:delivery] = "//cac:Delivery"
          # relative to delivery
          xpaths[:delivery_date]          = "cbc:ActualDeliveryDate"
          xpaths[:delivery_location_type] = "cac:DeliveryLocation/cbc:ID/@schemeID"
          xpaths[:delivery_location_id]   = "cac:DeliveryLocation/cbc:ID"
          xpaths[:delivery_address]       = "cac:DeliveryLocation/cac:Address/cbc:StreetName"
          xpaths[:delivery_city]          = "cac:DeliveryLocation/cac:Address/cbc:CityName"
          xpaths[:delivery_postalcode]    = "cac:DeliveryLocation/cac:Address/cbc:PostalZone"
          xpaths[:delivery_province]      = "cac:DeliveryLocation/cac:Address/cbc:CountrySubentity"
          xpaths[:delivery_country]       = "cac:DeliveryLocation/cac:Address/cac:Country/cbc:IdentificationCode"

        end
        xpaths
      end

      def payment_method_from_facturae(code)
        facturae_codes = {}
        Invoice::PAYMENT_CODES.each do |haltr_code, codes|
          facturae_codes[codes[:facturae]] = haltr_code
        end
        facturae_codes[code]
      end

      def payment_method_from_ubl(code)
        ubl_codes = {}
        Invoice::PAYMENT_CODES.each do |haltr_code, codes|
          ubl_codes[codes[:ubl]] = haltr_code
        end
        ubl_codes[code]
      end

      def float_parse(value)
        value = value.to_s.strip
        val = case value
              when /^-?[0-9]+$/
                value
              when /^-?[0-9]+\.[0-9]+$/
                value
              when /^-?[0-9]+,[0-9]+$/
                value.gsub(/,/,'.')
              when /^-?[0-9\.]+,[0-9]+$/
                value.gsub(/\./,'').gsub(/,/,'.')
              when /^-?[0-9,]+\.[0-9]+$/
                value.gsub(/,/,'')
              when /^-?[0-9,]+'[0-9]+$/
                value.gsub(/,/,'').gsub(/'/,'.')
              when /^-?[0-9.]+'[0-9]+$/
                value.gsub(/\./,'').gsub(/'/,'.')
              else
                '0'
              end
        val.to_f
      end

      def to_money(import, currency=nil, rounding_method=nil)
        currency ||= Setting.plugin_haltr['default_currency']
        currency = Money::Currency.new(currency)
        import = float_parse(import.to_s)
        import = BigDecimal.new(import.to_s) * currency.subunit_to_unit
        if import % 1 != 0
          rounding_method ||= :half_up
          case rounding_method.to_sym
          when :bankers
            import = import.round(0, BigDecimal::ROUND_HALF_EVEN)
          when :truncate
            import = import.to_i
          else # defaults to half_up
            import = import.round(0)
          end
        end
        Money.new(import.to_i, currency)
      end

      def extract_from_sbdh(doc)
        type = doc.xpath("//xmlns:StandardBusinessDocument/xmlns:StandardBusinessDocumentHeader/xmlns:DocumentIdentification/xmlns:Type").text
        namespace = doc.xpath("//xmlns:StandardBusinessDocument/xmlns:StandardBusinessDocumentHeader/xmlns:DocumentIdentification/xmlns:Standard").text
        extracted_doc = doc.xpath("//ns:#{type}", 'ns' => namespace)
        return Nokogiri.XML(extracted_doc.to_xml)
      end

      def root_namespace(doc)
        doc=Nokogiri::XML(doc) unless doc.is_a? Nokogiri::XML::Document
        if doc.root.nil?
          raise "Is not a valid XML"
        elsif doc.root.namespace.nil?
          raise "XML does not have a root namespace"
        elsif doc.root.namespace.href == "http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader"
          doc = Haltr::Utils.extract_from_sbdh(doc)
          Haltr::Utils.root_namespace(doc)
        else
          doc.root.namespace.href
        end
      end

      # With a hash of client attributes, this searches for clients by taxcode,
      # if it matches uses existing client, if not, creates a new one.
      # Then it compares client fields and creates a client_office if it differs.
      # returns:[ client, client_office=nil ]
      #
      def client_from_hash(client_hash)
        project = client_hash[:project]
        hook_retval = Redmine::Hook.call_hook(
          :client_from_hash_begin,
          client_hash: client_hash,
          project: project
        )
        if hook_retval.present?
          client_hash = hook_retval[0]
        end
        client = nil
        client_office = nil
        if client_hash[:country] and client_hash[:country].size == 3
          client_hash[:country] = SunDawg::CountryIsoTranslater.translate_standard(
            client_hash[:country], "alpha3", "alpha2"
          ).downcase rescue client_hash[:country]
        elsif client_hash[:country]
          client_hash[:country] = client_hash[:country].downcase
        end
        if project
          if client_hash[:endpointid].present? and client_hash[:schemeid].present?
            client = project.clients.where(
              'schemeid = ? and endpointid = ?', client_hash[:schemeid], client_hash[:endpointid]
            ).first
          end
          if client.blank? and client_hash[:taxcode].present?
            # to match ES12345678 when we have 12345678
            project.clients.where('taxcode like ?', "%#{client_hash[:taxcode]}").each do |c|
              if c.taxcode =~ /\A.{0,2}#{client_hash[:taxcode]}\z/
                client = c
                break
              end
            end
            unless client
              # to match 12345678 when we have ES12345678
              project.clients.where('? like concat("%", taxcode) and taxcode != ""', client_hash[:taxcode]).each do |c|
                if client_hash[:taxcode] =~ /\A.{0,2}#{c.taxcode}\z/
                  client = c
                  break
                end
              end
            end
          end
          if client.blank? and client_hash[:company_identifier].present?
            client = project.clients.where('company_identifier = ?', client_hash[:company_identifier]).first
          end
        end
        if client.blank?
          client = Client.new(client_hash)
          client.project = project
          external_company = nil
          # to match ES12345678 when we have 12345678
          ExternalCompany.where('taxcode like ?', "%#{client_hash[:taxcode]}").each do |ec|
            if ec.taxcode =~ /\A.{0,2}#{client_hash[:taxcode]}\z/
              external_company = ec
              break
            end
          end
          unless external_company
            # to match 12345678 when we have ES12345678
            ExternalCompany.where('? like concat("%", taxcode) and taxcode != ""', client_hash[:taxcode]).each do |ec|
              if client_hash[:taxcode] =~ /\A.{0,2}#{ec.taxcode}\z/
                external_company = ec
                break
              end
            end
          end
          if external_company
            client.company = external_company
          end
          client.language ||= User.current.language
          # do not add "validate: false" here or you'll end with duplicated
          # clients, client validates uniqueness of taxcode.
          unless client.valid?
            client.email = ''
            unless client.valid?
              # provem si només es un error de taxcode
              client.company_identifier = client.taxcode
              client.taxcode = ''
            end
          end
          unless client.valid?
            raise "#{I18n.t(:client)}: #{client.errors.full_messages.join('. ')}"
          end
          client.save!
        end

        # stored data may not match data in invoice, if it doesn't,
        # we create a client_office with data from invoice
        to_match = {
          full_address:         client_hash[:address].to_s.chomp,
          city:                 client_hash[:city].to_s.chomp,
          province:             client_hash[:province].to_s.chomp,
          postalcode:           client_hash[:postalcode].to_s.chomp,
          country:              client_hash[:country].to_s.chomp,
          name:                 client_hash[:name].to_s.chomp,
          edi_code:             client_hash[:edi_code].to_s.chomp,
          destination_edi_code: client_hash[:destination_edi_code].to_s.chomp
        }.reject {|k,v| v.blank? }
        # check if client data matches client_hash
        if !to_match.all? {|k, v| client.send(k).to_s.chomp.casecmp(v) == 0 }
          # check if any client_office matches client_hash
          client.client_offices.each do |office|
            if to_match.all? {|k, v| office.send(k).to_s.chomp.casecmp(v) == 0 }
              client_office = office
              break
            end
          end

          # client_office validates uniqueness of edi_code
          if client.edi_code.to_s.chomp.casecmp(client_hash[:edi_code].to_s.chomp) == 0
            client_hash[:edi_code] = ''
          end

          if client_office.nil?
            # client and all its client_offices differ from data in invoice
            client_office = ClientOffice.new(
              client_id:            client.id,
              address:              client_hash[:address].to_s.chomp,
              city:                 client_hash[:city].to_s.chomp,
              province:             client_hash[:province].to_s.chomp,
              postalcode:           client_hash[:postalcode].to_s.chomp,
              country:              client_hash[:country].to_s.chomp.downcase,
              name:                 client_hash[:name].to_s.chomp,
              edi_code:             client_hash[:edi_code].to_s.chomp,
              destination_edi_code: client_hash[:destination_edi_code].to_s.chomp
            )
            raise "#{l(:label_client_office)}: #{client_office.errors.full_messages.join('. ')}" unless client_office.save
            client.reload
          end
        end
        [client, client_office]
      end

    end
  end
end
