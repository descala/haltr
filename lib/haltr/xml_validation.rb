module Haltr 
  module XmlValidation

    # Use online service to validate facturae (spain)
    def facturae_errors(xml)
      tmp_file_name = Tempfile.new("facturae_utils_tmp.xml","tmp").path
      File.open(tmp_file_name, 'w') do |f|
        f.write(xml)
      end
      command = "#{File.dirname(__FILE__)}/facturae-validate-invoice.sh #{tmp_file_name}"
      output = `#{ command }`
      if $?.success?
        return []
      else
        return output.split("\n")
      end
    end

    # these are the xsl used in ubl:
    # biiubl20    = biicore + biirules
    # peppolubl20 = biicore + biirules + eugen
    # invoice#amend_of ? uses t14 (creditnote) : uses t10 (invoice)
    # donwloaded from http://www.invinet.org/recursos/conformance/download.html
    #   biicore-ubl-t10.xsl
    #   biicore-ubl-t14.xsl
    #   biirules-ubl-t10.xsl
    #   biirules-ubl-t14.xsl
    #   eugen-ubl-t10.xsl
    #   eugen-ubl-t14.xsl
    def ubl_errors(xml)
      errors = []
      doc = Nokogiri::XML(xml)
      xsl = File.read("#{File.dirname(__FILE__)}/xml_validation/BIIRULES-UBL-T10.xsl")
      xslt = Nokogiri::XSLT(xsl)
      svrl = xslt.transform(doc)
      # example error
      #  <svrl:failed-assert test="..." flag="fatal" location="...">
      #      <svrl:text>[BIIRULE-T10-R016]-Total charges MUST be equal to the sum of document level charges.</svrl:text>
      #  </svrl:failed-assert>
      svrl.xpath("//svrl:schematron-output/svrl:failed-assert").each do |error|
        errors << error.content
      end
      return errors
    end 
  end
end
