module ProjectHaltrPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
 
    base.send(:include, InstanceMethods)
 
    # Same as typing in the class
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      has_one :company
      has_many :clients
      has_many :invoices
      has_many :invoice_templates
      has_many :issued_invoices
      has_many :received_invoices
      has_many :payments
    end
 
  end
  
  module ClassMethods
  end
  
  module InstanceMethods
  end

end
