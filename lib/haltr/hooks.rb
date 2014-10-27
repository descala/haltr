module Haltr
  class Hooks < Redmine::Hook::ViewListener
    def controller_account_success_authentication_after(context={})
      company = context[:user].project.company rescue nil
      pending_auth = company ? company.companies_with_link_requests.size : 0
      if pending_auth > 0
        context[:controller].flash[:notice] ||= ""
        context[:controller].flash[:notice] << l(:pending_auth_requests, num: pending_auth)
      end
    end
  end
end
