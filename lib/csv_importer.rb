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

  def process_invoice_templates(options={})
    @debug         = options[:debug]
    templates      = {}
    template_lines = {}

    result_templates = CsvMapper::import(options[:templates_file]) do
      read_attributes_from_file
    end

    result_lines = CsvMapper::import(options[:template_lines_file]) do
      read_attributes_from_file
    end

    result_templates.each do |template|

      template_h = template.to_h

      num = template_h.delete(:number)
      date = template_h.delete(:date)

      # client
      client_taxcode = template_h.delete(:client_taxcode).gsub(" ","") unless template.client_taxcode.blank?
      if client_taxcode
        client = Client.where("taxcode = ? AND project_id = ?", client_taxcode, template.project_id).first
        if client.nil?
          puts "no client with taxcode '#{client_taxcode}'"
          next
        end
      else
        puts "no client taxcode provided: #{template.values.join(',')}"
        next
      end

      default_values = {
        currency: 'EUR',
        date: date.blank? ? Date.today : Date.strptime(date,'%d/%m/%Y'),
        client_id: client.id
      }

      template_h.reverse_merge!(default_values)
      templates[num] = InvoiceTemplate.new(template_h)
    end

    result_lines.each do |line|

      line_h = line.to_h
      num = line_h.delete(:invoice_number)

      unless templates.has_key? num
        puts "template line has incorrect invoice_number #{line.values.join(',')}"
        next
      end

      template_lines[num] ||= []
      template_lines[num] << InvoiceLine.new(line_h)
    end

    templates.each do |num, template|

      template.invoice_lines = template_lines[num] if template_lines.has_key? num

      begin
        template.save!
        puts "====================================" if @debug
      rescue ActiveRecord::RecordInvalid
        puts "Error importing template #{num}"
        puts "Invoice #{template.inspect}"
        puts template.errors.full_messages
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
