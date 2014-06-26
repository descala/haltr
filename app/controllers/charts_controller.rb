class ChartsController < ApplicationController
  unloadable
  layout 'haltr'
#  before_filter :find_optional_project
#  before_filter :authorize

  def invoice_totals
    user = User.current
    projects = user.projects.collect do |project|
      project if project.module_enabled? :haltr
    end.compact
    render json: IssuedInvoice.group_by_month(:date ).sum('total_in_cents/100'),
      library: {vAxis: {title: "#{l(:invoice_total)} (€) asdf" }}

  end
end
