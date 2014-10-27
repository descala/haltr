require 'render_anywhere'

module Haltr
  class Xml

    include RenderAnywhere

    def initialize
      set_render_anywhere_helpers(ApplicationHelper,HaltrHelper,InvoicesHelper)
    end

    def self.generate(invoice, format, local_certificate=false)
      new.generate(invoice,format,local_certificate)
    end

    def generate(invoice,format,local_certificate=false)
      # if it is an imported invoice, has not been modified and
      # invoice format  matches client format, send original file
      if invoice.original and !invoice.modified_since_created? and format == invoice.invoice_format
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
      end
      Haltr::Xml.clean_xml(xml)
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
