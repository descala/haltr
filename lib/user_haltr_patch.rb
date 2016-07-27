require_dependency 'user'

module UserHaltrPatch
  def self.included(base) # :nodoc:
    # Same as typing in the class
    base.class_eval do

      has_many :events
      has_many :companies, through: :projects
    end
  end
end
