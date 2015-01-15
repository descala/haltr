module CsvImporter

  include CsvMapper

  def process_clients(options={})
    @debug = options[:debug]
    @project = options[:project]
    @file_name = options[:file_name]

    map_clients = {
      "nomfiscal"  => "name",
      "dirfiscal"  => "address",
      "dircli2"    => "address2",
      "pobfiscal"  => "city",
      "provifiscal"=> "province",
      "dtofiscal"  => "postalcode",
      "fecalta"    => "created_at",
      "e_mail"     => "email",
      "paginaweb"  => "website",
      "docpag"     => "payment_method",
      "codcli"     => "company_identifier"
    }

    result = CsvMapper::import(@file_name) do
      read_attributes_from_file
    end

    result.each do |result_line|

      next if result_line['nifcli'].nil?

      # check existing taxcodes in the project
      client = result_line['nifcli'].blank? ? nil : @project.clients.find_by_taxcode(result_line['nifcli'])

      # if not found then it is a new taxcode
      client = Client.new(:project=> @project,
                          :invoice_format => 'signed_pdf',
                          :taxcode => result_line['nifcli'],
                          :terms => '0',
                          :currency => 'EUR' ) if client.nil?

      map_clients.each do |csv_field,client_field|
        puts "#{client_field} = #{csv_field} = #{result_line[csv_field]}" if @debug
        client[client_field] = result_line[csv_field].strip unless result_line[csv_field].nil?
      end

      if result_line['docpag'].upcase == 'R'
        client.payment_method = Invoice::PAYMENT_DEBIT
      else
        client.payment_method = Invoice::PAYMENT_TRANSFER
      end

      # deltete invalid email addresses
      client.email = '' unless client.email =~ /\A([\w\.\-\+]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

      begin
        client.save!
        puts "====================================" if @debug
      rescue Exception => error
        puts "Error importing #{result_line}"
        raise error
      end

    end
  end

  def process_invoices(options={})
    @debug = options[:debug]
    @project = options[:project]
    @file_name = options[:file_name]

    map_invoices = {
      "idfacv"        => "number",
      "observaciones" => "extra_info",
      "base"          => "import_in_cents",
      "docpag"        => "payment_method",
      "totapagar"     => "total_in_cents",
      "centrocoste"   => "accounting_cost"
    }


    result = CsvMapper::import(@file_name) do
      read_attributes_from_file
    end

    result.each do |result_line|

      next if result_line['idfacv'].nil?

      if invoice = @project.issued_invoices.find_by_number(result_line['idfacv'])
        invoice.destroy
      end

      invoice = IssuedInvoice.new(:project => @project,
                                  :currency => 'EUR' 
                                 )

      map_invoices.each do |csv_field,field|
        puts "#{field} = #{csv_field} = #{result_line[csv_field]}" if @debug
        invoice[field] = result_line[csv_field].strip unless result_line[csv_field].nil?
      end

      client_taxcode = result_line['nifcli'].gsub(" ","") unless result_line['nifcli'].nil?
      invoice.client = client_taxcode.blank? ? nil : @project.clients.find_by_taxcode(client_taxcode)
      if invoice.client.nil?
        puts "Invoice #{invoice.number}: client #{client_taxcode} not found"
        next
      end

      invoice.due_date = Date.strptime( result_line['fechacontable'],'%d/%m/%Y') unless result_line['fechacontable'].nil?
      invoice.date = Date.strptime( result_line['fechacontable'],'%d/%m/%Y') unless result_line['fechacontable'].nil?
      invoice.created_at = Date.strptime( result_line['fecha'],'%d/%m/%Y') unless result_line['fecha'].nil?
      invoice.date = Date.today if invoice.date.nil?
      invoice.invoice_lines << InvoiceLine.new(:quantity=>1, :description=>'Auxiliar', :price=>invoice.import_in_cents)
      invoice.state = 'closed'

      begin
        invoice.save!
        puts "====================================" if @debug
      rescue Exception => error
        puts "Error importing #{result_line}"
        puts "Invoice #{invoice.inspect}"
        raise error
      end

    end
  end

  def process_dir3entities(options={})

    entities = CsvMapper::import(options[:entities]) do
      read_attributes_from_file
    end

    Dir3Entity.delete_all
    entities.each do |l|
      Dir3Entity.create(l.members.inject({}) {|h,m| h[m] = l[m]; h})
    end
    puts "Entities imported: #{Dir3Entity.count}"

    relations = CsvMapper::import(options[:relations]) do
      read_attributes_from_file
    end

    Dir3.delete_all
    relations.each do |l|
      Dir3.create(l.members.inject({}) {|h,m| h[m] = l[m]; h})
    end
    puts "Relations imported: #{Dir3.count}"

  end

  def process_external_companies(options={})
    external_companies = CsvMapper::import(options[:external_companies]) do
      read_attributes_from_file
    end
    existing = []
    new      = []
    external_companies.each do |ec|
      ec_hash = ec.members.inject({}) {|h,m|
        h[m] = ec[m]; h.reverse_merge(
          {country: 'es', currency: 'EUR', invoice_format: 'aoc32'}
        )
      }
      current = ExternalCompany.find_by_taxcode(ec.taxcode)
      begin
        if current
          existing << ec
          current.update_attributes!(ec_hash)
        else
          new << ExternalCompany.create!(ec_hash)
        end
      rescue ActiveRecord::RecordInvalid => e
        puts "Invalid ExternalCompany: #{ec_hash[:taxcode]} (#{e})"
      end
    end
    puts "ExternalCompanies updated: #{existing.size}"
    puts "ExternalCompanies created: #{new.size}"
  end

end
