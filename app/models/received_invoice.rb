class ReceivedInvoice < InvoiceDocument

  belongs_to :created_from_invoice, class_name: 'IssuedInvoice'

  after_create :create_event
  before_save :update_imports

  include AASM

  aasm column: :state, skip_validation_on_save: true, whiny_transitions: true do
    state :received, initial: true
    state :accepted, :paid, :refused, :processing_pdf, :error

    before_all_events :aasm_create_event

    event :refuse do
      transitions from: [:accepted,:received], to: :refused
    end
    event :accept do
      transitions from: [:received,:accepted], to: :accepted
    end
    event :paid do
      transitions from: :accepted, to: :paid
    end
    event :unpaid do
      transitions from: :paid, to: :accepted
    end
    event :error_sending do
      transitions to: :error
    end
    event :processing_pdf do
      transitions to: :processing_pdf
    end
    event :processed_pdf do
      transitions from: :processing_pdf, to: :received
    end
  end

  def to_label
    "#{number}"
  end

  def sent?
    false
  end

  def past_due?
    !paid? && due_date && due_date < Date.today
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

    # the format of this invoice is the format of the document last sent
    sent_invoice_format = ExportChannels.format(issued.client.invoice_format)

    # copy issued invoice attributes
    ReceivedInvoice.new(
      issued.attributes.merge(
        state:     :received,
        transport: 'from_issued',
        project:   target.project,
        client:    client,
        bank_info: nil,
        invoice_format: sent_invoice_format,
        original:  (issued.last_sent_event.file rescue nil),
        created_from_invoice: issued,
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

  def file_name
    fn = read_attribute('file_name')
    if date
      "#{date.strftime("%Y%m%d")}_#{fn}"
    else
      "00000000_#{fn}"
    end
  end

  protected

  def create_event
    ReceivedInvoiceEvent.create!(:name=>self.transport,:invoice=>self,:user=>User.current)
  end

end
