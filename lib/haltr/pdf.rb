module Haltr
  class Pdf

    def self.generate(invoice)
      # https://github.com/mileszs/wicked_pdf/wiki/Background-PDF-creation-via-delayed_job-gem
      # create an instance of ActionView, so we can use the render method outside of a controller
      av = ActionView::Base.new()
      av.view_paths = ActionController::Base.view_paths

      #TODO: on InvoicesHelper we can't access authorize_for method from
      # ApplicationHelper but it works if we define it on HaltrHelper
      HaltrHelper.send(:define_method, :authorize_for) { |*args| false }

      # need these in case your view constructs any links or references any helper methods.
      av.class_eval do
        include Rails.application.routes.url_helpers
        include ApplicationHelper
        include HaltrHelper
        include InvoicesHelper
        include Redmine::I18n
      end

      pdf_html = av.render :template => "invoices/show_pdf.html.erb",
        :layout => "layouts/invoice.html", :locals => { :invoice => invoice }

      # use wicked_pdf gem to create PDF from the doc HTML
      WickedPdf.new.pdf_from_string(pdf_html, :page_size => 'A4')
    end

  end
end
