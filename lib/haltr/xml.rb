require 'render_anywhere'

module Haltr
  class Xml

    include RenderAnywhere

    def initialize
      set_render_anywhere_helpers(ApplicationHelper,HaltrHelper,InvoicesHelper)
    end

    def self.generate(invoice, format, local_certificate=false, as_file=false, force=false)
      new.generate(invoice,format,local_certificate, as_file, force)
    end

    def generate(invoice,format,local_certificate=false, as_file=false, force=false)
      # if it is an imported invoice, has not been modified and
      # invoice format  matches client format, send original file
      # check also original_root_namespace to verify that original is an xml,
      # it could be in other formats, like EDI
      if invoice.send_original? and !force and invoice.original_root_namespace
        xml = invoice.original
      else
        if format == 'efffubl'
          pdf = Base64::encode64(Haltr::Pdf.generate(invoice))
        else
          pdf = nil
        end
        client = invoice.client
        if invoice.client_office
          # overwrite client attributes with its office
          ClientOffice::CLIENT_FIELDS.each do |f|
            client[f] = invoice.client_office.send(f)
          end
        end
        xml = render(
          :template => "invoices/#{format}",
          :locals   => { :@invoice => invoice,
                         :@company => invoice.company,
                         :@client  => client,
                         :@efffubl_base64_pdf => pdf,
                         :@format  => format,
                         :@local_certificate  => local_certificate },
          :formats  => :xml,
          :layout   => false
        )
        # client can have xpaths in xpaths_from_original, if so, replace
        # generated ones by original, refs #5938
        if invoice.original.present? and client.xpaths_from_original.present?
          doc      = Nokogiri.parse(xml)
          doc_orig = Nokogiri.parse(invoice.original)
          client.xpaths_from_original.each_line do |xpath|
            orig_fragment = doc_orig.at_xpath(xpath)
            orig_fragment ||= ''
            doc.at_xpath(xpath).replace(orig_fragment) rescue nil
          end
          xml = doc.to_s
        end
        xml = Haltr::Xml.clean_xml(xml)
      end
      if as_file
        xml_file = Tempfile.new("invoice_#{invoice.id}.xml")
        xml_file.write(xml)
        xml_file.close
        xml_file
      else
        xml
      end
    end

    def self.clean_xml(xml)
      xsl =<<XSL
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="/">
    <xsl:copy-of select="."/>
  </xsl:template>
</xsl:stylesheet>
XSL
      doc  = Nokogiri::XML(xml)
      xslt = Nokogiri::XSLT(xsl)
      out  = xslt.transform(doc)
      out.to_xml
    end

  end

end
