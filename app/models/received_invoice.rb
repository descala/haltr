# to draw states graph execute:
#   rake state_machine:draw FILE=invoice.rb CLASS=ReceivedInvoice
class ReceivedInvoice < InvoiceDocument

  unloadable

  after_create :create_event

  state_machine :state, :initial => :received do
    before_transition do |invoice,transition|
      unless Event.automatic.include?(transition.event.to_s)
        Event.create(:name=>transition.event.to_s,:invoice=>invoice,:user=>User.current)
      end
    end

    event :refuse do
      transition [:accepted,:received] => :refused
    end
    event :accept do
      transition [:received,:accepted] => :accepted
    end
    event :paid do
      transition :accepted => :paid
    end
    event :unpaid do
      transition :paid => :accepted
    end
  end

  def to_label
    "#{number}"
  end

  def past_due?
    #TODO
    false
  end

  def label
    l(self.class)
  end

  def valid_signature?
    events.sort.each do |e|
      return true  if %w( success_validating_signature ).include? e.name
      return false if %w( error_validating_signature discard_validating_signature ).include? e.name
    end
    return false
  end

  # remove colons "1,23" => "1.23"
  def import=(v)
    i = Money.new(((v.is_a?(String) ? v.gsub(',','.') : v).to_f * 100).round, currency)
    write_attribute :import_in_cents, i.cents
  end

  def self.create_from_issued(issued, project)
    target = project.company
    source = issued.project.company
    client = target.project.clients.find_by_taxcode(source.taxcode)
    client ||= Client.create!(
      project_id:     target.project_id,
      name:           source.name,
      taxcode:        source.taxcode,
      address:        source.address,
      city:           source.city,
      postalcode:     source.postalcode,
      province:       source.province,
      website:        source.website,
      email:          source.email,
      country:        source.country,
      currency:       source.currency,
      invoice_format: source.invoice_format,
      schemeid:       source.schemeid,
      endpointid:     source.endpointid,
      language:       source.language,
      allowed:        nil
    )
    # copy issued invoice attributes
    ReceivedInvoice.new(
      issued.attributes.merge(
        state:     :received,
        transport: 'from_issued',
        project:   target.project,
        client:    client,
        bank_info: nil,
        original:  (issued.last_sent_event.file rescue nil),
        invoice_lines: issued.invoice_lines.collect {|il|
          new_il = il.dup
          new_il.taxes = il.taxes.collect {|t|
            Tax.new(
              name:     t.name,
              percent:  t.percent,
              category: t.category,
              comment:  t.comment
            )
          }
          new_il
        }
      )
    ).save(validate: false)
  end

  protected

  def create_event
    ReceivedInvoiceEvent.create(:name=>self.transport,:invoice=>self,:user=>User.current)
  end

end
