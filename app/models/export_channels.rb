class ExportChannels 

  unloadable

  # TODO: move this settings to activerecord
  def self.available
    {
      'paper'         => { :format=>nil,          :channel=>nil} ,
      'ublinvoice_20' => { :format=>'ubl21',      :channel=>'free_ubl', :validate => [:client_has_email, :ubl_invoice_has_no_taxes_withheld] },
      'facturae_30'   => { :format=>'facturae30', :channel=>'free_xml', :validate => [:client_has_email, :invoice_has_taxes] },
      'facturae_31'   => { :format=>'facturae31', :channel=>'free_xml', :validate => [:client_has_email, :invoice_has_taxes] },
      'facturae_32'   => { :format=>'facturae32', :channel=>'free_xml', :validate => [:client_has_email, :invoice_has_taxes] },
      'signed_pdf'    => { :format=>'pdf', :channel=>'free_pdf', :validate => :client_has_email },
      'aoc'           => { :format=>'facturae30', :channel=>'free_aoc', :private=>true, :validate => :invoice_has_taxes },
      'aoc31'         => { :format=>'facturae31', :channel=>'free_aoc', :private=>true, :validate => :invoice_has_taxes },
      'aoc32'         => { :format=>'facturae32', :channel=>'free_aoc', :private=>true, :validate => :invoice_has_taxes }
    }
  end

  def self.default
    'signed_pdf'
  end

  def self.available?(id)
    available.include? id
  end

  def self.format(id)
    available[id][:format] if available? id
  end

  def self.channel(id)
    available[id][:channel] if available? id
  end

  def self.validations(id)
    return [] if available[id][:validate].nil?
    available[id][:validate].is_a?(Array) ? available[id][:validate] : [available[id][:validate]]
  end

  def self.for_select(current_project)
    available.collect {|k,v|
      unless User.current.admin? or User.current.allowed_to?(:use_restricted_channels, current_project)
        next if v[:private]
      end
      [ I18n.t(k), k ]
    }.compact.sort {|a,b| a[1] <=> b[1] }
  end

  def self.path(id)
    part1 = "#{Setting.plugin_haltr['export_channels_path']}/#{self.channel(id)}"
  end
end

