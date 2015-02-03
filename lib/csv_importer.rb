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
      "codcli"     => "company_identifier",
      "language"   => "language",
      "invoice_format" => "invoice_format",
      "country" => "country"
    }

    result = CsvMapper::import(@file_name) do
      read_attributes_from_file
    end

    result.each do |result_line|

      taxcode = result_line['nifcli'] rescue result_line['taxcode']
      payment_method = result_line['docpag'] rescue result_line['payment_method']

      next if taxcode.nil?

      # check existing taxcodes in the project
      client = taxcode.blank? ? nil : @project.clients.find_by_taxcode(taxcode)

      # if not found then it is a new taxcode
      client = Client.new(:project=> @project,
                          :invoice_format => 'signed_pdf',
                          :taxcode => taxcode,
                          :terms => '0',
                          :currency => 'EUR' ) if client.nil?

      map_clients.each do |csv_field,client_field|
        begin
          client.send("#{client_field}=", result_line[csv_field].strip)
          puts "#{client_field} = #{csv_field} = #{result_line[csv_field]}" if @debug
        rescue NameError
          client.send("#{client_field}=", result_line[client_field].strip) if result_line[client_field]
        end
      end

      if payment_method == 'R'
        client.payment_method = Invoice::PAYMENT_DEBIT
      else
        client.payment_method = Invoice::PAYMENT_TRANSFER
      end

      unless client.email =~ /\A([\w\.\-\+]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
        emails = client.email.gsub(' ','').split(/[,;]/)
        client.email = emails.shift
        if emails.size > 0
          emails.each do |email|
            next if Person.find_by_email(email)
            person = Person.new(first_name: email, last_name: email, email: email, client: client)
            client.people << person
          end
        end
      end

      client.bank_info = @project.company.bank_infos.first

      begin
        client.save!
        puts "====================================" if @debug
      rescue ActiveRecord::RecordInvalid
        puts client.attributes
        puts client.errors.messages
        exit
      rescue Exception => error
        puts "Error importing #{result_line}"
        raise error
      end
    end
  end

  def process_invoices(options={})
    project = options[:project]

    result_invoices = CsvMapper::import(options[:file_name]) do
      read_attributes_from_file
    end

    result_invoices.each do |invoice_os|

      client_taxcode = invoice_os.taxcode
      if client_taxcode

        client = Client.where("taxcode = ?", client_taxcode).first
        if client.nil?
          puts "no client with taxcode '#{client_taxcode}'"
          next
        end
      else
        puts "no client taxcode provided: #{invoice_os.values.join(',')}"
        next
      end

      invoice = IssuedInvoice.new(
        project: project,
        currency: 'EUR',
        date: Date.strptime(invoice_os.date,'%d/%m/%Y'),
        client: client,
        number: invoice_os.number,
        extra_info: invoice_os.extra_info
      )

      invoice_line = InvoiceLine.new(
        invoice: invoice,
        price: invoice_os.price,
        quantity: 1,
        unit: 1,
        description: invoice_os.description
      )

      invoice.invoice_lines << invoice_line

      Tax.create!(invoice_line: invoice_line, name: "IVA", percent: 0, default: nil, category: "E", comment: "")

      begin
        invoice.save!
      rescue ActiveRecord::RecordInvalid
        puts "Error importing invoice"
        puts "Invoice #{invoice.inspect}"
        puts invoice.errors.full_messages
      end

    end
  end

  def process_dir3entities(options={})
    entities = CsvMapper::import(options[:entities]) do
      read_attributes_from_file
    end
    existing = []
    new      = []
    error    = []
    entities.each do |l|
      current = Dir3Entity.find_by_code(l.code)
      l_hash = l.members.inject({}) {|h,m| h[m] = l[m] unless l[m].blank? ; h}
      l_hash[:postalcode] = l_hash[:postalcode].strip.rjust(5, "0") rescue nil
      begin
        if current
          existing << l
          current.update_attributes!(l_hash)
        else
          new << Dir3Entity.create!(l_hash)
        end
      rescue ActiveRecord::RecordInvalid => e
        error << l_hash
        puts "Invalid Dir3Entity: #{l_hash[:code]} (#{e})"
      end
    end
    puts "Entities updated: #{existing.size}"
    puts "Entities created: #{new.size}"
    return [existing.size, new.size, error.size]
  end

  def process_external_companies(options={})
    external_companies = CsvMapper::import(options[:external_companies]) do
      read_attributes_from_file
    end
    existing = []
    new      = []
    error    = []
    external_companies.each do |ec|
      ec_hash = ec.members.inject({}) {|h,m| h[m] = ec[m] unless ec[m].blank? ; h}
      ec_hash[:country] ||= 'es'
      ec_hash[:currency] ||= 'EUR'
      ec_hash[:invoice_format] ||= 'aoc32'
      ec_hash[:postalcode] = ec_hash[:postalcode].strip.rjust(5, "0") rescue nil
      ec_hash.delete(:postalcode) if ec_hash[:postalcode].blank?
      ec_hash[:visible_dir3] = true if ec_hash[:oficines_comptables] or ec_hash[:unitats_tramitadores] or ec_hash[:organs_gestors]
      current = ExternalCompany.find_by_taxcode(ec.taxcode)
      begin
        if current
          existing << ec
          current.update_attributes!(ec_hash)
        else
          new << ExternalCompany.create!(ec_hash)
        end
      rescue ActiveRecord::RecordInvalid => e
        error << ec_hash
        puts "Invalid ExternalCompany: #{ec_hash[:taxcode]} (#{e})"
      end
    end
    puts "ExternalCompanies updated: #{existing.size}"
    puts "ExternalCompanies created: #{new.size}"
    return [existing.size, new.size, error.size]
  end

end
