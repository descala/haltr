module CsvImporter

  include CsvMapper

  def process_clients(options={})
    @project = options[:project]
    @file_name = options[:file_name]
    lang = @project.users.reject {|u| u.admin? }.first.language

    result = CsvMapper::import(@file_name) do
      read_attributes_from_file
    end

    valid_clients=[]
    invalid_clients=[]

    result.each do |result_line|

      taxcode = result_line['taxcode'].downcase
      if taxcode[0...2].downcase == @project.company.country
        taxcode2 = taxcode[2..-1]
      else
        taxcode2 = "#{@project.company.country}#{taxcode}"
      end
      company = Company.where(
        "taxcode in (?, ?) and (public='public')", taxcode, taxcode2
      ).first
      company ||= ExternalCompany.where("taxcode in (?, ?)", taxcode, taxcode2).first
      if company
        client = Client.new(company: company)
      else
        client = Client.new(result_line.to_h)
      end
      client.language ||= lang
      client.project = @project
      client.taxcode = taxcode

      unless client.valid?
        invalid_clients << client.taxcode
        puts "client #{client.taxcode}: #{client.errors.full_messages.join(', ')}"
      else
        valid_clients << client.taxcode
        puts "client #{client.taxcode}: OK#{" (linked)" if client.company}"
        client.save!
      end
    end
    puts "------------"
    puts "created: #{valid_clients.size} clients. Ignored: #{invalid_clients.size} (#{invalid_clients.join(', ')})"
  end

  def process_invoices(options={})
    project = options[:project]

    result_invoices = CsvMapper::import(options[:file_name]) do
      read_attributes_from_file
    end

    result_invoices.each do |invoice_os|

      client_taxcode = invoice_os.taxcode
      if client_taxcode

        client = project.clients.find_by_taxcode(client_taxcode)
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
