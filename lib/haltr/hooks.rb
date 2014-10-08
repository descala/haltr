module Haltr
  class Hooks < Redmine::Hook::ViewListener
    def controller_account_success_authentication_after(context={})
      pending_auth = context[:user].project.company.companies_with_link_requests.size
      if pending_auth > 0
        context[:controller].flash[:notice] ||= ""
        context[:controller].flash[:notice] << l(:pending_auth_requests, num: pending_auth)
      end
    rescue
    end
  end
end
