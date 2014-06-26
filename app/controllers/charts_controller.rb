class ChartsController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :only => [:invoice_status]
  before_filter :authorize, :only => [:invoice_status]

  def invoice_total
    user = User.current
    projects = user.projects.collect do |project|
      project if project.module_enabled? :haltr and user.allowed_to?(:general_use, project)
    end.compact
    if projects.any?
      chart_data = []
      projects.each do |project|
        chart_data << {
          name: project.company.name,
          data: project.issued_invoices.group_by_month(:date, format: "%Y/%m").sum('total_in_cents/100') 
        }
      end
      render json: chart_data.chart_json
    else
      render_404
    end
  end

  def invoice_status
    chart_data = @project.issued_invoices.group(:state).group_by_month(:date, format: "%Y/%m").sum('total_in_cents/100')
    # TODO translate state name
    # chart_data.each do |state_hash|
    #   .... l("state_#{state_hash['name']}")
    # end
    render json: chart_data.chart_json
  end

end
