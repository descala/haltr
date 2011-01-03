class ActiveResource::Base

  # connect to an url depending on node
  # http://groups.google.com/group/rubyonrails-core/browse_thread/thread/e8fe3e30f9c70380
  def self.connect(current_site)
    self.site = current_site
    connection(:refresh)
  end

  # paginate active_resource
  # http://rubyroyd.com/2009/02/12/activeresource-pagination
  def self.paginate(*args)
    total_members, per_page = 0

    options = args.detect{|a| a.is_a?(Hash) && a.has_key?(:params)}
    if options
      params = options[:params]
    else
      params = {}
    end

    current_page = params[:page] || 1
    per_page = params[:per_page] ||= 30

    rs = find(*args)

    if rs[0].respond_to?(:pagination_members_total) && rs[0].respond_to?(:pagination_members_per_page)
      total_members = rs[0].pagination_members_total
      per_page = rs[0].pagination_members_per_page
      rs.delete_at 0
    end

    WillPaginate::Collection.create(current_page, per_page, total_members) do |pager|
      pager.replace rs
    end
  rescue ActiveResource::TimeoutError => e
    raise Errno::ECONNREFUSED.new("Timeout while connecting to #{self.site} (#{e.message})")
  end

end
