require 'render_anywhere'

module Haltr
  class Edifact

    include RenderAnywhere

    def initialize
      set_render_anywhere_helpers(ApplicationHelper,HaltrHelper,InvoicesHelper)
    end

    def self.generate(invoice, as_file=false, force=false)
      new.generate(invoice, as_file, force)
    end

    def generate(invoice, as_file=false, force=false)
      # if it is an imported invoice, has not been modified and
      # invoice format  matches client format, send original file
      # check also original_root_namespace to verify that original is an edi,
      # it could be in other formats, like EDI
      if invoice.send_original? and !force and invoice.original =~ /^UNA/
        edi = invoice.original
      else
        client = invoice.client
        if invoice.client_office
          # overwrite client attributes with its office
          ClientOffice::CLIENT_FIELDS.each do |f|
            client[f] = invoice.client_office.send(f)
          end
        end
        edi = render(
          :template => "invoices/edifact",
          :locals   => { :@invoice => invoice,
                         :@company => invoice.company,
                         :@client  => client },
          :layout   => false
        )
        # count total lines from UNH to UNT (both included), to {segmentcount}
        unh_to_unt = /^UNH.*^UNT/m.match(edi).to_s
        edi.gsub!('{segmentcount}',unh_to_unt.lines.count.to_s)
      end
      if as_file
        edi_file = Tempfile.new("invoice_#{invoice.id}.edi")
        edi_file.write(edi)
        edi_file.close
        edi_file
      else
        edi
      end
    end

  end

end
