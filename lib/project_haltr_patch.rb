require_dependency 'project'

module ProjectHaltrPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
 
    base.send(:include, InstanceMethods)
 
    # Same as typing in the class
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      has_one :company
      has_many :clients
    end
 
  end
  
  module ClassMethods
  end
  
  module InstanceMethods
    def invoice_templates
      self.clients.collect {|c| c.invoice_templates}.flatten.compact
    end
    def invoices
      self.clients.collect {|c| c.invoice_documents}.flatten.compact
    end
  end

end
 
# Add module to Project
Project.send(:include, ProjectHaltrPatch)
