require 'render_anywhere'

module Haltr
  class Pdf

    include RenderAnywhere

    def initialize
      set_render_anywhere_helpers(ApplicationHelper,HaltrHelper,InvoicesHelper)
    end

    def self.generate(invoice, as_file=false)
      new.generate(invoice, as_file)
    end

    def generate(invoice, as_file=false)
      pdf_html = render(
        :template => "invoices/show_pdf.html.erb",
        :layout => "layouts/invoice.html",
        :locals => { :invoice => invoice, :@is_pdf => true }
      )
      # use wicked_pdf gem to create PDF from the doc HTML
      options =  {
        :page_size => 'A4',
        :margin =>
        {
          :top => 20,
          :bottom => 20,
          :left   => 30,
          :right  => 20
        }
      }
      pdf = WickedPdf.new.pdf_from_string(pdf_html, options)
      if as_file
        pdf_file = Tempfile.new(invoice.pdf_name,:encoding => 'ascii-8bit')
        pdf_file.write(pdf)
        pdf_file.close
        pdf_file
      else
        pdf
      end
    end

  end
end
