module Haltr 
  module XmlValidation

    # Use online service to validate facturae (spain)
    def facturae_errors_online(xml, leave_xml_file=nil)
      tmp_file = Tempfile.new("facturae_errors.xml","tmp")
      File.open(tmp_file.path, 'w') do |f|
        f.write(xml)
      end
      tmp_file.close
      command = "#{File.dirname(__FILE__)}/facturae-validate-invoice.sh #{tmp_file.path}"
      output = `#{ command }`
      if leave_xml_file
        # TODO file gets deleted
        puts xml
      else
        tmp_file.unlink
      end
      if $?.success?
        return []
      else
        return output.split("\n")
      end
    end

    # Use XSD to validate facturae
    def facturae_errors_xsd(xml, leave_xml_file=nil)
      errors = []
      Dir.chdir("#{File.dirname(__FILE__)}/xml_validation") do
        doc = Nokogiri::XML(xml)
        xsd = Nokogiri::XML::Schema(File.read("Facturaev3_2.xsd"))
        errors = xsd.validate(doc)
      end
      if leave_xml_file
        tmp_file = Tempfile.new("ubl_errors.xml","tmp")
        File.open(tmp_file.path, 'w') do |f|
          f.write(xml)
        end
        # TODO file gets deleted
        puts xml.to_s
      end
      return errors
    end

    # these are the xsl used in ubl:
    # peppolubl20 = biicore + biirules + eugen
    # invoice#amend_of ? uses t14 (creditnote) : uses t10 (invoice)
    # donwloaded from http://www.invinet.org/recursos/conformance/download.html
    #   biicore-ubl-t10.xsl
    #   biicore-ubl-t14.xsl
    #   biirules-ubl-t10.xsl
    #   biirules-ubl-t14.xsl
    #   eugen-ubl-t10.xsl
    #   eugen-ubl-t14.xsl
    def ubl_errors(xml, leave_xml_file=nil)
      errors = []
      doc = Nokogiri::XML(xml)
      xsl = File.read("#{File.dirname(__FILE__)}/xml_validation/BIIRULES-UBL-T10.xsl")
      xslt = Nokogiri::XSLT(xsl)
      svrl = xslt.transform(doc)
      # example error
      #  <svrl:failed-assert test="..." flag="fatal" location="...">
      #      <svrl:text>[BIIRULE-T10-R016]-Total charges MUST be equal to the sum of document level charges.</svrl:text>
      #  </svrl:failed-assert>
      svrl.xpath("//svrl:schematron-output/svrl:failed-assert[@flag='fatal']").each do |error|
        errors << error.content
      end
      if leave_xml_file
        tmp_file = Tempfile.new("ubl_errors.xml","tmp")
        File.open(tmp_file.path, 'w') do |f|
          f.write(xml)
        end
        # TODO file gets deleted
        puts xml.to_s
      end
      return errors
    end 
  end
end
