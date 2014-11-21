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
        :locals => { :invoice => invoice },
        :margin => {:top => 20,
          :bottom => 20,
          :left   => 30,
          :right  => 20}
      )
      # use wicked_pdf gem to create PDF from the doc HTML
      WickedPdf.new.pdf_from_string(pdf_html, :page_size => 'A4')
    end

  end
end
