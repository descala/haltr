module Haltr
  module Xml

    def self.generate(invoice, format)
      xml = RenderXmlController.new.render_to_string(
        :template => "invoices/#{format}",
        :locals   => { :@invoice => invoice,
                       :@company => invoice.company,
                       :@client  => invoice.client },
        :formats  => :xml,
        :layout   => false
      )
      self.clean_xml(xml)
    end

    def self.efffubl(invoice, pdf)
      xml = RenderXmlController.new.render_to_string(
        :template => "invoices/efffubl",
        :locals   => { :@invoice => invoice,
                       :@company => invoice.company,
                       :@client  => invoice.client,
                       :@efffubl_base64_pdf => pdf },
        :formats  => :xml,
        :layout   => false
      )
      self.clean_xml(xml)
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

  class RenderXmlController < AbstractController::Base
    include AbstractController::Rendering
    include AbstractController::Layouts
    include AbstractController::Helpers
    include AbstractController::Translation
    include AbstractController::AssetPaths

    # Uncomment if you want to use helpers
    # defined in ApplicationHelper in your views
    helper ApplicationHelper
    helper HaltrHelper
    helper InvoicesHelper

    # Make sure your controller can find views
    self.view_paths = ApplicationController.view_paths

    # You can define custom helper methods to be used in views here
    # helper_method :current_admin
    # def current_admin; nil; end

    def set_localization
    end

    def render_to_string(options)
      render options
    end
  end

end
