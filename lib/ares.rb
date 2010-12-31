class ActiveResource::Base

  # connect to an url depending on node
  # http://groups.google.com/group/rubyonrails-core/browse_thread/thread/e8fe3e30f9c70380
  def self.connect(current_site)
    self.site = current_site
    connection(:refresh)
  end

end
