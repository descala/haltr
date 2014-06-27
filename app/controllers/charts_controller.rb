class ChartsController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :only => [:invoice_status]
  before_filter :authorize, :only => [:invoice_status]
  include ChartsHelper

  def invoice_total
    projects = haltr_projects
    if projects.any?
      chart_data = []
      projects.each do |project|
        chart_data << {
          name: project.company.name,
          data: project.issued_invoices.where(["date > ?", 5.years.ago]).group_by_month(:date, format: "%Y/%m").sum('total_in_cents/100') 
        }
      end
      render json: chart_data.chart_json
    else
      render_404
    end
  end

  def invoice_status
    chart_data = @project.issued_invoices.where(["date > ?", 5.years.ago]).group(:state).group_by_month(:date, format: "%Y/%m").sum('total_in_cents/100')
    # TODO translate state name
    # chart_data.each do |state_hash|
    #   .... l("state_#{state_hash['name']}")
    # end
    render json: chart_data.chart_json
  end

end
