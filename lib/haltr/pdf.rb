require 'render_anywhere'

module Haltr
  class Pdf

    include RenderAnywhere

    def initialize
      set_render_anywhere_helpers(ApplicationHelper,HaltrHelper,InvoicesHelper)
    end

    def self.generate(invoice)
      new.generate(invoice)
    end

    def generate(invoice)
      pdf_html = render(
        :template => "invoices/show_pdf.html.erb",
        :layout => "layouts/invoice.html",
        :locals => { :invoice => invoice }
      )
      options = {
        :page_size => 'A4',
        :margin => { :bottom => 20 }
      }

      unless invoice.company.company_identifier.blank?
        # NOTE
        # To display headers and footers you need to install
        # an statically linked version of wkhtmltopdf
        # http://wkhtmltopdf.org/downloads.html
        options[:footer] = {:left => "#{I18n.t(:field_company_identifier)}: #{invoice.company.company_identifier}", :font_size => 8, :spacing => 10 }
      end
      # use wicked_pdf gem to create PDF from the doc HTML
      WickedPdf.new.pdf_from_string(pdf_html,options)

    end

  end
end
