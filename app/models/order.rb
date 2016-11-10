class Order < ActiveRecord::Base
  unloadable

  belongs_to :project
  belongs_to :client
  belongs_to :client_office
  belongs_to :invoice
  has_many :comments, :as => :commented, :dependent => :delete_all, :order => "created_on"
  has_many :events, :order => :created_at
  after_create :create_event

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
    taxcode:    "/cac:PartyTaxScheme/cbc:CompanyID",
    taxcode2:   "/cac:PartyLegalEntity/cbc:CompanyID",
    taxcode3:   "/cac:PartyIdentification/cbc:ID",
    name:       "/cac:PartyName/cbc:Name",
    endpointid: "/cbc:EndpointID", # peppol
    address:    "/cac:PostalAddress/cbc:StreetName",
    city:       "/cac:PostalAddress/cbc:CityName",
    postalcode: "/cac:PostalAddress/cbc:PostalZone",
    province:   "/cac:PostalAddress/cbc:CountrySubentity",
    country:    "/cac:PostalAddress/cac:Country/cbc:IdentificationCode",
  }

  def self.regexps(edi)
    !!(edi =~ REGEXPS[:num_pedido]) ? REGEXPS : REGEXPS2
  end

  def regexps
    Order.regexps(original)
  end

  def self.create_from_edi(file, project)
    edi = Redmine::CodesetUtil.replace_invalid_utf8(file.read)
    order = ReceivedOrder.new(
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
      doc = Haltr::Utils.extract_from_sbdh(doc)
    end
    seller_taxcodes = []
    seller_taxcodes << Haltr::Utils.get_xpath(doc, "#{XPATHS_ORDER[:seller]}#{XPATHS_PARTY[:taxcode]}")
    seller_taxcodes << Haltr::Utils.get_xpath(doc, "#{XPATHS_ORDER[:seller]}#{XPATHS_PARTY[:taxcode2]}")
    seller_taxcodes << Haltr::Utils.get_xpath(doc, "#{XPATHS_ORDER[:seller]}#{XPATHS_PARTY[:taxcode3]}")
    seller_taxcodes << Haltr::Utils.get_xpath(doc, "#{XPATHS_ORDER[:seller]}#{XPATHS_PARTY[:endpointid]}")
    seller_taxcodes = seller_taxcodes.reject {|t| t.blank? }.uniq
    seller_taxcodes.collect! {|t| t.gsub(/\s/,'') }
    seller_endpoint = Haltr::Utils.get_xpath(doc, "#{XPATHS_ORDER[:seller]}#{XPATHS_PARTY[:endpointid]}")
    buyer_taxcodes  = []
    buyer_taxcodes << Haltr::Utils.get_xpath(doc, "#{XPATHS_ORDER[:buyer]}#{XPATHS_PARTY[:taxcode]}")
    buyer_taxcodes << Haltr::Utils.get_xpath(doc, "#{XPATHS_ORDER[:buyer]}#{XPATHS_PARTY[:taxcode2]}")
    buyer_taxcodes << Haltr::Utils.get_xpath(doc, "#{XPATHS_ORDER[:buyer]}#{XPATHS_PARTY[:taxcode3]}")
    buyer_taxcodes << Haltr::Utils.get_xpath(doc, "#{XPATHS_ORDER[:buyer]}#{XPATHS_PARTY[:endpointid]}")
    buyer_taxcodes = buyer_taxcodes.reject {|t| t.blank? }.uniq
    buyer_taxcodes.collect! {|t| t.gsub(/\s/, '') }
    buyer_endpoint  = Haltr::Utils.get_xpath(doc, "#{XPATHS_ORDER[:buyer]}#{XPATHS_PARTY[:endpointid]}")

    if seller_taxcodes.include?(project.company.taxcode) or project.company.endpointid == seller_endpoint
      client_role = :buyer
      client_taxcodes = buyer_taxcodes
    elsif buyer_taxcodes.include?(project.company.taxcode) or project.company.endpointid == buyer_endpoint
      client_role = :seller
      client_taxcodes = seller_taxcodes
    else
      peppolid = ", #{project.company.schemeid} #{project.company.endpointid}"
      raise I18n.t :taxcodes_does_not_belong_to_self,
        :tcs => "#{buyer_taxcodes.join('/')} - #{seller_taxcodes.join('/')}",
        :tc  => "#{project.company.taxcode}#{peppolid if peppolid.size > 3}"
    end

    client_hash = {}
    XPATHS_PARTY.each do |k,v|
      next if k =~ /taxcode/
      client_hash[k] = Haltr::Utils.get_xpath(doc, "#{XPATHS_ORDER[client_role]}#{v}")
    end
    client_hash[:taxcode] = client_taxcodes.first
    client_hash[:project] = project

    order = (client_role == :buyer) ? ReceivedOrder.new : IssuedOrder.new
    order.client, order.client_office = Haltr::Utils.client_from_hash(client_hash)
    order.project  = project
    order.original = xml
    order.filename = file.original_filename

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
    Order.first(conditions: ["project_id = ? and id > ? and type = ?", project.id, id, type])
  end

  def previous
    Order.last(conditions: ["project_id = ? and id < ? and type = ?", project.id, id, type])
  end

  def ubl_invoice
    if xml?
      begin
        xslt = Nokogiri.XSLT(File.open(
          File.dirname(__FILE__) +
          "/../../lib/haltr/xslt/Invinet-Order2Invoice.xsl",'rb'
        ))
        xslt.transform(
          Nokogiri::XML(original),
          ['ID', "'#{IssuedInvoice.next_number(project)}'",
           'IssueDate', "'#{Date.today}'"]
        ).to_s
      rescue
        raise "Error with XSLT transformation"
      end
    else
      raise "Original must be in XML format to create an invoice"
    end
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

end
