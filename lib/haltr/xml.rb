require 'render_anywhere'

module Haltr
  class Xml

    include RenderAnywhere

    def initialize
      set_render_anywhere_helpers(ApplicationHelper,HaltrHelper,InvoicesHelper)
    end

    def self.generate(invoice, format)
      new.generate(invoice,format)
    end

    def generate(invoice,format)
      xml = render(
        :template => "invoices/#{format}",
        :locals   => { :@invoice => invoice,
                       :@company => invoice.company,
                       :@client  => invoice.client },
        :formats  => :xml,
        :layout   => false
      )
      Haltr::Xml.clean_xml(xml)
    end

    def self.efffubl(invoice, pdf)
      new.efffubl(invoice,pdf)
    end

    def efffubl(invoice, pdf)
      xml = render(
        :template => "invoices/efffubl",
        :locals   => { :@invoice => invoice,
                       :@company => invoice.company,
                       :@client  => invoice.client,
                       :@efffubl_base64_pdf => pdf },
        :formats  => :xml,
        :layout   => false
      )
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
