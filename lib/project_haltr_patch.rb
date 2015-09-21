module ProjectHaltrPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
 
    base.send(:include, InstanceMethods)
 
    # Same as typing in the class
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      has_one :company
      has_many :clients
      has_many :people, :through => :clients
      has_many :client_offices, :through => :clients
      has_many :mandates, :through => :clients
      has_many :invoices
      has_many :invoice_templates
      has_many :issued_invoices
      has_many :quotes
      has_many :received_invoices
      has_many :payments
      has_many :draft_invoices
      has_many :events
      has_many :import_errors
    end
 
  end
  
  module ClassMethods
  end
  
  module InstanceMethods

    # prevent project.issued_invoices to include DraftInvoices
    def issued_invoices
      super.where("type != 'DraftInvoice'")
    end

  end

end
