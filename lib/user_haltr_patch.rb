require_dependency 'user'

module UserHaltrPatch
  def self.included(base) # :nodoc:
    # Same as typing in the class
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      has_many :events
    end
  end
end
 
User.send(:include, UserHaltrPatch)
