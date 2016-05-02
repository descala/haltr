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
        val.blank? ? nil : val.collect {|v| v.text }.join(" ")
      end

      def xpaths_for(format)
        xpaths = {}.with_indifferent_access
        if format =~ /facturae/
          xpaths[:invoice_number]     = "//Invoices/Invoice/InvoiceHeader/InvoiceNumber"
          xpaths[:invoice_series]     = "//Invoices/Invoice/InvoiceHeader/InvoiceSeriesCode"
          xpaths[:amend_of]           = "//Invoices/Invoice/InvoiceHeader/Corrective/InvoiceNumber"
          xpaths[:amend_of_serie]     = "//Invoices/Invoice/InvoiceHeader/Corrective/InvoiceSeriesCode"
          xpaths[:amend_type]         = "//Invoices/Invoice/InvoiceHeader/Corrective/CorrectionMethod"
          xpaths[:amend_reason]       = "//Invoices/Invoice/InvoiceHeader/Corrective/ReasonCode"
          xpaths[:invoice_date]       = "//Invoices/Invoice/InvoiceIssueData/IssueDate"
          xpaths[:invoicing_period_start] = "//Invoices/Invoice/InvoiceIssueData/InvoicingPeriod/StartDate"
          xpaths[:invoicing_period_end]   = "//Invoices/Invoice/InvoiceIssueData/InvoicingPeriod/EndDate"
          xpaths[:invoice_total]      = "//Invoices/Invoice/InvoiceTotals/InvoiceTotal"
          xpaths[:invoice_import]     = "//Invoices/Invoice/InvoiceTotals/TotalGrossAmountBeforeTaxes"
          xpaths[:discount_percent]   = "//Invoices/Invoice/InvoiceTotals/GeneralDiscounts/Discount/DiscountRate"
          xpaths[:discount_text]      = "//Invoices/Invoice/InvoiceTotals/GeneralDiscounts/Discount/DiscountReason"
          xpaths[:payments_on_account]= "//Invoices/Invoice/InvoiceTotals/TotalPaymentsOnAccount"
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
          xpaths[:seller_email]       = "//Parties/SellerParty/*/ContactDetails/ElectronicMail"
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
          xpaths[:invoice_number]     = "/xmlns:Invoice/cbc:ID"
          xpaths[:invoice_date]       = "/xmlns:Invoice/cbc:IssueDate"
          xpaths[:invoice_total]      = "/xmlns:Invoice/cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount"
          xpaths[:invoice_import]     = "/xmlns:Invoice/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount"
          xpaths[:payment_method]     = "/xmlns:Invoice/cac:PaymentMeans/cbc:PaymentMeansCode"
          xpaths[:invoice_due_date]   = "/xmlns:Invoice/cac:PaymentMeans/cbc:PaymentDueDate"
          xpaths[:seller_taxcode]     = "/xmlns:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID"
          xpaths[:seller_name]        = "/xmlns:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyName/cbc:Name"
          xpaths[:seller_name2]       = nil
          xpaths[:seller_address]     = [ "/xmlns:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:StreetName",
                                          "/xmlns:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:BuildingNumber" ] 
          xpaths[:seller_province]    = "/xmlns:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:CountrySubentity"
          xpaths[:seller_countrycode] = "/xmlns:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode"
          xpaths[:seller_website]     = "/xmlns:Invoice/cac:AccountingSupplierParty/cac:Party/cbc:WebsiteURI"
          xpaths[:seller_email]       = "/xmlns:Invoice/cac:AccountingSupplierParty/cac:Party/cac:Contact/cbc:ElectronicMail"
          xpaths[:seller_cp_city]     = [ "/xmlns:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:PostalZone",
                                          "/xmlns:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:CityName" ]
          xpaths[:seller_cp_city2]    = nil
          xpaths[:buyer_taxcode]      = "/xmlns:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID"
          xpaths[:buyer_taxcode_id]   = "/xmlns:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"
          xpaths[:buyer_endpoint_id]  = "/xmlns:Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID"
          xpaths[:buyer_name]         = "/xmlns:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyName/cbc:Name"
          xpaths[:buyer_name2]        = nil
          xpaths[:buyer_address]      = [ "/xmlns:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:StreetName",
                                          "/xmlns:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:BuildingNumber" ] 
          xpaths[:buyer_province]     = "/xmlns:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:CountrySubentity"
          xpaths[:buyer_countrycode]  = "/xmlns:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode"
          xpaths[:buyer_website]      = "/xmlns:Invoice/cac:AccountingCustomerParty/cac:Party/cbc:WebsiteURI"
          xpaths[:buyer_email]        = "/xmlns:Invoice/cac:AccountingCustomerParty/cac:Party/cac:Contact/cbc:ElectronicMail"
          xpaths[:buyer_cp_city]      = [ "/xmlns:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:PostalZone",
                                          "/xmlns:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:CityName" ]
          xpaths[:buyer_cp_city2]     = nil
          xpaths[:currency]           = "/xmlns:Invoice/cbc:DocumentCurrencyCode"

          xpaths[:global_taxes]       = ["/xmlns:Invoice/cac:TaxTotal/cac:TaxSubtotal",
                                         "/xmlns:Invoice/cac:WithholdingTaxTotal/cac:TaxSubtotal"]
          # relative to global_taxes
          xpaths[:gtax_category]      = "cac:TaxCategory/cbc:ID"
          xpaths[:gtax_percent]       = "cac:TaxCategory/cbc:Percent"
          xpaths[:gtax_name]          = "cac:TaxCategory/cac:TaxScheme/cbc:ID"

          xpaths[:invoice_lines]      = "//cac:InvoiceLine"
          # relative to invoice_lines
          xpaths[:i_transaction_ref]  = "IssuerTransactionReference" # todo
          xpaths[:r_contract_reference] = "ReceiverContractReference" # todo
          xpaths[:line_quantity]      = "cbc:InvoicedQuantity"
          xpaths[:line_description]   = "cac:Item/cbc:Name"
          xpaths[:line_price]         = "cac:Price/cbc:PriceAmount"
          xpaths[:line_unit]          = "cbc:InvoicedQuantity/@unitCode"
          xpaths[:line_taxes]         = ["cac:Item/cac:ClassifiedTaxCategory"]
          xpaths[:line_notes]         = "cac:Item/cbc:Description"
          xpaths[:line_code]          = "cac:Item/cac:SellersItemIdentification/cbc:ID"
          xpaths[:line_discounts]     = "cac:AllowanceCharges[/cbc:ChargeIndicator='false']/*"
          xpaths[:line_charges]       = "cac:AllowanceCharges[/cbc:ChargeIndicator='true']/*"
          xpaths[:file_reference]     = "FileReference" # todo
          xpaths[:sequence_number]    = "SequenceNumber" # todo
          xpaths[:tax_event_code]     = "SpecialTaxableEvent/SpecialTaxableEventCode" # todo

          xpaths[:tax_event_reason]   = "SpecialTaxableEvent/SpecialTaxableEventReason" # todo


          xpaths[:delivery_notes]     = "DeliveryNotesReferences/DeliveryNote" # todo
          # relative to invoice_lines/delivery_notes_references/delivery_note
          xpaths[:delivery_note_num]  = "DeliveryNoteNumber" # todo

          xpaths[:ponumber]           = "ReceiverTransactionReference" # todo
          # relative to invoice_lines/discounts
          xpaths[:line_discount_percent] = "cbc:MultiplierFactorNumeric"
          xpaths[:line_discount_text]    = "cbc:AllowanceChargeReason"
          # relative to invoice_lines/charges
          xpaths[:line_charge]        = "cbc:Amount"
          xpaths[:line_charge_reason] = "cbc:AllowanceChargeReason"
          # relative to invoice_lines/taxes
          xpaths[:tax_name]           = "cac:TaxScheme/cbc:ID"
          xpaths[:tax_category]       = "cbc:ID"

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

    end
  end
end
