class InvoiceImg < ActiveRecord::Base
  unloadable

  belongs_to :invoice
  validate :has_associated_invoice

  serialize :data

  def has_associated_invoice
    errors.add(:invoice) unless self.invoice and self.invoice.is_a? InvoiceDocument
  end

  after_initialize do
    self.data = {} if data.nil?
    self.data[:tags] = {} if tags.nil?
    self.data[:tokens] = {} if tokens.nil?
  end

  after_create do
    update_invoice if data and tags
    if tags.any?
      Event.create(name: 'processed_pdf', invoice: invoice)
    else
      EventError.create(name: 'processed_pdf', invoice: invoice, notes: 'OCR failed')
    end
  end

  before_update do
    # TODO update invoice
  end

  def update_invoice
    tags[:language]  = what_language unless tagv(:language)
    invoice.number   = tagv(:invoice_number)
    invoice.date     = tagv(:issue)
    invoice.due_date = tagv(:due)
    if t=tagv(:subtotal)
      if invoice.invoice_lines.count == 1
        # Updates auxiliar line
        aux_line = invoice.invoice_lines.first
        aux_line.price = decimal(t)
        aux_line.save
      else
        # Creates auxiliar line
        aux_line = InvoiceLine.new(
          quantity: 1,
          description: 'Original invoice in PDF format',
          price: decimal(t)
        )
        invoice.invoice_lines << aux_line
      end
    end
    if t=tagv(:tax_percentage) and invoice.invoice_lines.any?
      invoice.invoice_lines.each do |invoice_line|
        if invoice_line.taxes.count == 1
          tax = invoice_line.taxes.first
          tax.percent = decimal(t)*100
          tax.save
        else
          tax = Tax.new(
            name: 'IVA',
            percent: decimal(t)*100
          )
          invoice_line.taxes << tax
        end
      end
    end
    if invoice.is_a? ReceivedInvoice
      invoice.state=:received
    else
      invoice.state=:new
    end
    if !invoice.client
      if tagv(:seller_taxcode)
        invoice.client = invoice.company.project.clients.where(taxcode: tagv(:seller_taxcode)).first
        if !invoice.client and  tagv(:seller_name)
          new_client = Client.new(
            project: invoice.project,
            name:    tagv(:seller_name),
            taxcode: tagv(:seller_taxcode),
            country: iso_country_from_text(tagv(:seller_country)),
            language: tags[:language]
          )
          invoice.client = new_client if new_client.save
        end
      end
    end
    invoice.client = fuzzy_match_client unless invoice.client
    invoice.save(validate: false)
    self.save
  end

  def tagv(key)
    reference = tags[key]
    if tokens[reference]
      tokens[reference]['text']
    else
      reference
    end
  rescue
    nil
  end

  def tags
    data[:tags]
  end

  def useful_tokens
    useful = {}
    tokens.each do |number, attributes|
      if attributes[:text] and attributes[:text].size > 1
        useful[number] = attributes
        width =  attributes[:x1].to_i - attributes[:x0].to_i
        height = attributes[:y1].to_i - attributes[:y0].to_i
        if height > width
          # Rotate -90
          useful[number][:x1] = attributes[:x0].to_i + height
          useful[number][:y1] = attributes[:y0].to_i + width
        end
      end
    end
    return useful
  end

  def tokens
    data[:tokens]
  end

  def text(token)
    data[:tokens][token][:text] rescue nil
  end

  # "€600.00"
  # "18,00%"
  def decimal(value)
    cents = value.gsub(/\D/,'').to_i
    cents / 100.0
  rescue
    0
  end

  def width
    data['width']
  end

  def height
    data['height']
  end

  def fuzzy_match_client
    require 'fuzzy_match'
    match_tokens = tokens.collect do |k,v|
      v[:text].split(/\.|:/) if v[:text] =~ /\d/
    end.flatten.compact
    fm = FuzzyMatch.new(match_tokens, threshold: 0.6)
    best_client_match = nil
    best_text = nil
    best_score = 0.6
    invoice.company.project.clients.each do |client|
      text, score = fm.find_with_score(client.taxcode)
      if score and  score > best_score
        best_client_match = client
        best_score = score
        best_text = text
      end
    end
    if best_client_match
      tokens.each do |number, token|
        tags['seller_taxcode'] = number if token[:text].include?(best_text)
      end
    end
    company_match = fm.find(invoice.company.taxcode)
    if company_match
      tokens.each do |number, token|
        if token[:text].include?(company_match)
          tags['buyer_taxcode'] = number 
        end
      end
    end
    return best_client_match
  end

  def what_language
    require 'whatlanguage'
    invoice_string = tokens.collect do |k,v|
      v[:text] unless v[:text] =~ /\d/
    end.flatten.compact.join(' ')
    WhatLanguage.new.language_iso(invoice_string)
  end

  def iso_country_from_text(country_txt)
    fm = FuzzyMatch.new(ISO3166::Country.translations(tagv(:language)))
    # ["ES", "Espanya"]
    fm.find(country_txt)[0].downcase rescue invoice.company.country
  end

  def all_possible_tags
    %w(invoice_number language seller_country seller_name seller_taxcode buyer_taxcode issue due subtotal tax_percentage tax_amount total)
  end

end
