desc "Export ReceivedInvoice train data"

namespace :haltr do
  namespace :export do
    task :train => :environment do |task, args|

      begin
        require 'csv'
        csv_headers  = CSV.generate do |csv|
          csv << [:id,:client,:taxcode,:number,:width,:height,:tokens]
        end
        puts csv_headers
          InvoiceImg.all.each do |img|
            csv_string = CSV.generate do |csv|
              invoice = img.invoice
              client = invoice.client
              tokens = img.tokens.collect do |num,token|
                [img.tags_inverted[num],token[:x0],token[:y0],token[:x1],token[:y1],token[:text]]
              end
              csv << [img.id,client.name,client.taxcode,invoice.number,img.width,img.height,tokens.to_json]
            end
            puts csv_string
          end
      rescue => error
        puts "Error: #{error}"
        raise error
      end
    end
  end
end

