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
      if invoice.send_original? and !force
        xml = invoice.original
      else
        if format == 'efffubl'
          pdf = Base64::encode64(Haltr::Pdf.generate(invoice))
        else
          pdf = nil
        end
        xml = render(
          :template => "invoices/#{format}",
          :locals   => { :@invoice => invoice,
                         :@company => invoice.company,
                         :@client  => invoice.client,
                         :@efffubl_base64_pdf => pdf,
                         :@format  => format,
                         :@local_certificate  => local_certificate },
          :formats  => :xml,
          :layout   => false
        )
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
