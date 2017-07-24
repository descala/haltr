class Order < ActiveRecord::Base

  belongs_to :project
  has_one :company, through: :project
  belongs_to :client
  belongs_to :client_office
  belongs_to :invoice
  has_many :comments, -> {order "created_on"}, :as => :commented, :dependent => :delete_all
  has_many :events, -> {order 'created_at DESC, id DESC'}
  after_create :create_event

  after_create :notify_users_by_mail, if: Proc.new {|o|
    o.project.company.order_notifications
  }

  acts_as_event

  REGEXPS = {
    # camps que es desaran a la bbdd
    num_pedido:      /ORD=([^:]*)::/,
    fecha_pedido:    /ORD=[^:]*::([^+]*)\+\+.'/,
    lugar_entrega:   /CLO=:[^+]*\+([^+]*)\+/,
    fecha_entrega:   /DIN=([^']*)'/,
    fecha_documento: /FIL=[0-9]+\+[0-9]\+([^']*)'/,
    # camps que no es desen a la bbdd
    datos_proveedor: %r{
      SDT=(?<codigo_po>[^:]*):
      (?<nombre_po>[^+]*)\+
      (?<sociedad>[^+]*)\+
      (?<direccion1>[^:]*):
      (?<direccion2>[^:]*):
      (?<direccion3>[^:]*):
      (?<direccion4>[^:]*):
      (?<cp>[^']*)'
    }x,
    datos_cliente: %r{
      CDT=(?<codigo_po>[^:]*):
      (?<nombre_po>[^+]*)\+
      (?<sociedad>[^+]*)\+
      (?<direccion1>[^:]*):
      (?<direccion2>[^:]*):
      (?<direccion3>[^:]*):
      (?<direccion4>[^:]*):
      (?<cp>[^']*)'
    }x,
    direccion_entrega: %r{
      CLO=:(?<codigo_cliente>[^+]*)\+
      (?<lugar_entrega>[^+]*)\+
      (?<direccion1>[^:]*):
      (?<direccion2>[^:]*):
      (?<direccion3>[^:]*):
      (?<direccion4>[^:]*):
      (?<cp>[^']*)'
    }x,
    lineas_pedido: %r{
      OLD=(?<linea_pedido>[^+]*)\+:
      (?<codigo_articulo_proveedor>[^+]*)\+\+:
      (?<codigo_articulo_cliente>[^+]*)\+
      (?<unidades_consumo>[^+]*)\+
      (?<cantidad>[^+]*)\+
      (?<precio>[^+]*)\+\+\+
      (?<descripcion>[^']*)'
    }x
  }

  REGEXPS2 = {
    # camps que es desaran a la bbdd
    num_pedido:      /BGM\+[^+]+\+([0-9]+)\+/,
    fecha_pedido:    /DTM\+137:([0-9]+):/,
    lugar_entrega:   /NAD\+DP\+[^+]*\+[^+]*\+([^+]*\+[^+]*\+[^+]*\+[^+]*\+[^+]*)'/,
    fecha_entrega:   /DTM\+2:([0-9]+):/,
    fecha_documento: /UNB\+[^+]*\+[^+]*\+[^+]*\+([^+]*):/,
    # camps que no es desen a la bbdd
    datos_proveedor:   /NAD\+SU\+(?<codigo_po>[^:+]*):/,
    datos_cliente:     /NAD\+BY\+(?<codigo_po>[^:+]*):/,
    direccion_entrega: %r{
      NAD\+DP\+(?<codigo_cliente>[^+:]*)[^+]*\+[^+]*\+
      (?<lugar_entrega>[^+]*)\+
      (?<direccion1>[^+]*)\+
      (?<direccion2>[^+]*)\+
      (?<direccion3>[^+]*)\+
      (?<cp>[^+]*)'
    }x,
    lineas_pedido:     %r{
      LIN\+(?<linea_pedido>[^+]*)\+[^+]*\+(?<codigo_articulo_cliente>[^+]*)'
      PIA[^']*\+(?<codigo_articulo_proveedor>[^+]*)'
      IMD[^:]*:::(?<descripcion>[^']*)'
      QTY\+21:(?<cantidad>[^']*)'
      QTY\+59:(?<unidades_consumo>[^']*)'
      MOA[^']*'
      PRI\+AAB:(?<precio_bruto>[^']*)'
      PRI\+AAA:(?<precio_neto>[^']*)'
      TAX[^']*'
      MOA[^']*'
    }x,
  }

  XPATHS_ORDER = {
    sbdh:            "//xmlns:StandardBusinessDocument/xmlns:StandardBusinessDocumentHeader",
    num_pedido:      "/xmlns:Order/cbc:ID",
    fecha_pedido:    "/xmlns:Order/cbc:IssueDate",
    lugar_entrega:   "/xmlns:Order/cac:Delivery/cac:DeliveryLocation/cbc:ID",
    fecha_entrega:   "/xmlns:Order/cac:Delivery/cac:RequestedDeliveryPeriod/cbc:EndDate",
    fecha_documento: "/xmlns:Order/cbc:IssueDate",
    buyer:           "/xmlns:Order/cac:BuyerCustomerParty/cac:Party",
    seller:          "/xmlns:Order/cac:SellerSupplierParty/cac:Party",
    # camps que no es desen a la bbdd
    #datos_proveedor:   "",
    #datos_cliente:     "",
    #direccion_entrega: "",
    #lineas_pedido:     "",
  }

  # relatius a seller o buyer
  XPATHS_PARTY = {
    taxcode:            "/cac:PartyTaxScheme/cbc:CompanyID",
    company_identifier: "/cac:PartyLegalEntity/cbc:CompanyID",
    endpointid:         "/cbc:EndpointID", # peppol
    endpointid2:        "/cac:PartyIdentification/cbc:ID",
    name:               "/cac:PartyName/cbc:Name",
    address:            "/cac:PostalAddress/cbc:StreetName",
    city:               "/cac:PostalAddress/cbc:CityName",
    postalcode:         "/cac:PostalAddress/cbc:PostalZone",
    province:           "/cac:PostalAddress/cbc:CountrySubentity",
    country:            "/cac:PostalAddress/cac:Country/cbc:IdentificationCode",
  }

  STATES = %w(received accepted refused closed)

  def self.regexps(edi)
    !!(edi =~ REGEXPS[:num_pedido]) ? REGEXPS : REGEXPS2
  end

  def regexps
    Order.regexps(original)
  end

  def self.create_from_edi(file, project)
    edi = Redmine::CodesetUtil.replace_invalid_utf8(file.read)
    order = Order.new(
      project: project,
      original: edi,
      filename: file.original_filename
    )
    rgxps = order.regexps
    rgxps.keys.each do |key|
      next unless order.respond_to? "#{key}="
      if edi =~ rgxps[key]
        order.send("#{key}=", rgxps[key].match(edi)[1])
      else
        order.send("#{key}=", "?")
      end
    end
    order.save!
    order
  end

  def self.create_from_xml(file, project)
    file_name = nil
    if file.respond_to? :filename             # Mail::Part
      file_name = file.filename
    elsif file.respond_to? :original_filename # UploadedFile
      file_name = file.original_filename
    elsif file.respond_to? :path              # File (tests)
      file_name = File.basename(file.path)
    else
      file_name = "order.xml"
    end

    xml = file.read
    doc = Nokogiri::XML(xml)

    if doc.child and doc.child.name == "StandardBusinessDocument"
      # PEPPOL data from SBDH
      sender_schemeid, sender_endpointid = doc.at(
        "#{XPATHS_ORDER[:sbdh]}/xmlns:Sender/xmlns:Identifier"
      ).text.to_s.split(':')
      sender_schemeid = B2b::Peppol.iso2sch(sender_schemeid)
      receiver_schemeid, receiver_endpointid = doc.at(
        "#{XPATHS_ORDER[:sbdh]}/xmlns:Receiver/xmlns:Identifier"
      ).text.to_s.split(':')
      receiver_schemeid = B2b::Peppol.iso2sch(receiver_schemeid)

      doc = Haltr::Utils.extract_from_sbdh(doc)
    end

    # PEPPOL data from XML (if data from SBDH is blank)
    [XPATHS_PARTY[:endpointid], XPATHS_PARTY[:endpointid2]].each do |xpath|
      sender_endpointid = Haltr::Utils.get_xpath(
        doc, "#{XPATHS_ORDER[:buyer]}#{xpath}") if sender_endpointid.blank?
      sender_schemeid = Haltr::Utils.get_xpath(
        doc, "#{XPATHS_ORDER[:buyer]}#{xpath}/@schemeID") if sender_schemeid.blank?
      receiver_endpointid = Haltr::Utils.get_xpath(
        doc, "#{XPATHS_ORDER[:seller]}#{xpath}") if receiver_endpointid.blank?
      receiver_schemeid = Haltr::Utils.get_xpath(
        doc, "#{XPATHS_ORDER[:seller]}#{xpath}/@schemeID") if receiver_schemeid.blank?
    end

    # our company data must match seller data
    unless receiver_endpointid == project.company.endpointid and
        receiver_schemeid == project.company.schemeid
      # seller does not match
      raise I18n.t :endpoint_does_not_belong_to_self,
        :tcs => "#{receiver_schemeid}:#{receiver_endpointid}",
        :tc  => "#{project.company.schemeid}:#{project.company.endpointid}"
    end

    client_hash = {}
    XPATHS_PARTY.each do |k,v|
      next if k =~ /endpointid/
      client_hash[k] = Haltr::Utils.get_xpath(doc, "#{XPATHS_ORDER[:buyer]}#{v}")
    end
    client_hash[:endpointid] = sender_endpointid
    client_hash[:schemeid]   = sender_schemeid
    client_hash[:project]    = project

    # if client has no country, assume it is the same as the seller's
    if client_hash[:country].nil?
      client_hash[:country] = Haltr::Utils.get_xpath(doc, "#{XPATHS_ORDER[:seller]}#{XPATHS_PARTY[:country]}")
    end

    order = Order.new
    order.client, order.client_office = Haltr::Utils.client_from_hash(client_hash)
    order.project  = project
    order.original = xml
    order.filename = file.original_filename rescue 'Unknown'

    XPATHS_ORDER.each do |key, xpath|
      next unless order.respond_to?("#{key}=")
      value = Haltr::Utils.get_xpath(doc, xpath)
      order.send("#{key}=",value)
    end
    order.filename = file_name
    unless order.save
      raise "ORDER: #{order.errors.full_messages.join('. ')}"
    end
    order
  end

  def xml?
    original =~ /^<\?xml/
  end

  def edi?
    !xml?
  end

  def datos_proveedor
    if edi?
      original.scan(regexps[:datos_proveedor])
      Hash[ Regexp.last_match.names.zip( Regexp.last_match.captures ) ]
    end
  rescue
    {}
  end

  def datos_cliente
    if edi?
      original.scan(regexps[:datos_cliente])
      Hash[ Regexp.last_match.names.zip( Regexp.last_match.captures ) ]
    end
  rescue
    {}
  end

  def direccion_entrega
    if edi?
      original.scan(regexps[:direccion_entrega])
      Hash[ Regexp.last_match.names.zip( Regexp.last_match.captures ) ]
    end
  rescue
    {}
  end

  def lineas_pedido
    if edi?
      # http://stackoverflow.com/questions/6804557
      # http://stackoverflow.com/questions/11688726
      # removed \n to match multiple lines
      original.gsub("\n",'').to_enum(:scan, regexps[:lineas_pedido]).map do
        Hash[ Regexp.last_match.names.zip( Regexp.last_match.captures ) ]
      end
    end
  rescue
    []
  end

  def next
    Order.where("id > ? and project_id = ?", id, project.id).first
  end

  def previous
    Order.where("id < ? and project_id = ?", id, project.id).last
  end

  def ubl_invoice(number=nil,date=nil)
    number ||= IssuedInvoice.next_number(project)
    date   ||= Date.today
    if xml?
      begin
        xslt = Nokogiri.XSLT(File.open(
          File.dirname(__FILE__) +
          "/../../lib/haltr/xslt/Invinet-Order2Invoice.xsl",'rb'
        ))
        invoice = xslt.transform(
          Nokogiri::XML(original),
          ['ID', "'#{number}'",
           'IssueDate', "'#{date}'"]
        )
        # Adds the PostalAddress of our Company, only if not already pressent in Order
        unless invoice.at('//cac:AccountingSupplierParty/cac:Party/cac:PostalAddress', cac: 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2')

          supplier_party_name_node = invoice.at('//cac:AccountingSupplierParty/cac:Party/cac:PartyName', cac: 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2')
          ubl_address = InvoicesController.renderer.render(
            :partial => "invoices/ubl_address",
            :format => :xml,
            :locals => {:entity => project.company},
            layout: false
          )
          supplier_party_name_node.after("<cac:PostalAddress>#{ubl_address}</cac:PostalAddress>")
        end
        Haltr::Xml.clean_xml(invoice.to_s)
      rescue
        raise "Error with XSLT transformation"
      end
    else
      raise "Original must be in XML format to create an invoice"
    end
  end

  def order_response(time=Time.now)

    response = OrdersController.renderer.render(
      :template => "orders/order_response",
      :locals   => {
        :@order => self,
        :issue_date => time.strftime("%Y-%m-%d"),
        :issue_time => time.strftime("%H:%M:%S")
      },
      :formats  => :xml,
      :layout   => false
    )

    # Amb Nokogiri s'hi afegeix, de la Order:
    #
    #  cbc:DocumentCurrencyCode
    #  cac:BuyerCustomerParty
    #  cac:SellerSupplierParty
    #
    # TODO tenir en compte diferents prefixes
    #      assumim cbc i cac

    order_doc = Nokogiri.XML(original)
    response_doc = Nokogiri.XML(response)

    customer = response_doc.at('//cbc:DocumentCurrencyCode')
    customer.replace(order_doc.at('//cbc:DocumentCurrencyCode'))
    customer = response_doc.at('//cac:BuyerCustomerParty')
    customer.replace(order_doc.at('//cac:BuyerCustomerParty'))
    seller = response_doc.at('//cac:SellerSupplierParty')
    seller.replace(order_doc.at('//cac:SellerSupplierParty'))

    # Elimina nodes que no calen
    response_doc.xpath('//cac:Contact').remove rescue nil
    response_doc.xpath('//cac:PostalAddress').remove rescue nil
    response_doc.xpath('//cac:PartyTaxScheme').remove rescue nil

    Haltr::Xml.clean_xml(response_doc.to_s)
  end

  protected

  def create_event
    if self.original
      event = EventWithFile.new(:name=>'uploaded',:order_id=>self.id,
                                :user=>User.current,:file=>self.original,
                                :filename=>self.filename,:project=>self.project)
    else
      event = Event.new(:name=>'uploaded',:order_id=>self.id,
                        :user=>User.current,:project=>self.project)
    end
    #event.audits = self.last_audits_without_event
    event.save!
  end

  private

  def visible?(usr=nil)
    (usr || User.current).allowed_to?(:use_orders, project)
  end

  def notify_users_by_mail
    MailNotifier.order_add(self).deliver
  end

  def updated_on
    updated_at
  end

end
