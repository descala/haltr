module Haltr
  class Sender

    # search invoice.client.invoice_format in channels.yml in order to choose a
    # method for sending the invoice. There are 3 options:
    #   1) Leave invoice in a folder
    #   2) Use a class to send the invoice (immediate_perform)
    #   3) Queue a delayed::job (perform)
    # for 1) this method creates a file and calls "queue_file"
    # for 2) and 3) it queues or sends the invoice
    #
    def self.send_invoice(invoice, user, local_certificate=false, invoice_file=nil)
      unless invoice.valid?
        EventError.create(
          :name    => 'error_sending',
          :notes   => invoice.errors.full_messages.join(', '),
          :invoice => invoice
        )
        raise invoice.errors.full_messages.join(', ')
      end
      export_id = invoice.client.invoice_format
      unless ExportChannels.can_send?(export_id)
        EventError.create(
          :name    => 'error_sending',
          :notes   => ExportChannels.l(export_id),
          :invoice => invoice
        )
        raise ExportChannels.l(export_id)
      end
      format = ExportChannels.format export_id
      if invoice_file
        doc = File.read(invoice_file)
      else
        if format == 'pdf'
          doc = Haltr::Pdf.generate(invoice)
        elsif format == 'none'
          doc = nil
        elsif format == 'original'
          unless invoice.original
            raise 'invoice original is nil!'
          end
          doc = invoice.original
        else
          doc = Haltr::Xml.generate(invoice,format,local_certificate)
        end
      end

      if ExportChannels.folder(export_id).nil?
        # Use special class to send invoice
        class_for_send = ExportChannels.class_for_send(export_id).constantize rescue nil
        sender = class_for_send.new(invoice, user)
        if sender.respond_to?(:immediate_perform)
          # send using immediate_perform
          sender.immediate_perform(doc)
        elsif sender.respond_to?(:perform)
          # send using Delayed::Job
          if format == 'pdf'
            sender.pdf = doc
          else
            sender.xml = doc
          end
          Delayed::Job.enqueue sender
        else
          raise "Error in channels.yml: check configuration for #{export_id}"
        end
      else
        # send to folder
        unless invoice_file
          if format == 'pdf'
            invoice_file = Tempfile.new(invoice.pdf_name,:encoding => 'ascii-8bit')
            invoice_file.write(doc)
            invoice_file.close
          else
            invoice_file = Tempfile.new("invoice_#{invoice.id}.xml")
            invoice_file.write(doc)
            invoice_file.close
          end
        end
        # store file in a folder (queue)
        file_ext = (format == "pdf") ? "pdf" : "xml"
        path = ExportChannels.path export_id
        dest = "#{path}/" + "#{invoice.client.hashid}_#{invoice.id}" +
          ".#{file_ext}".gsub(/\//,'')
        i = 2
        while File.exists? dest
          dest="#{path}/" + "#{invoice.client.hashid}_#{i}_#{invoice.id}" +
            ".#{file_ext}".gsub(/\//,'')
          i+=1
        end
        if Rails.env == "development"
          FileUtils.cp(invoice_file.path, './queued_file.data')
        end
        FileUtils.mv(invoice_file.path, dest)
      end
    end
  end

end
