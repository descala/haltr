class ChartsController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :only => [:invoice_status,:top_clients]
  before_filter :authorize, :only => [:invoice_status,:top_clients]
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
    final_json = JSON.parse(chart_data.chart_json)
    final_json.each do |h|
      state_key = h['name']
      h['name'] = l("state_#{state_key}")
    end
    render json: final_json 
  end

  def top_clients
    top_clients = @project.issued_invoices.where(["date > ?", 5.years.ago]).group(:client).limit(5).order("sum_total_in_cents_100 DESC").sum('total_in_cents/100')
    client_ids = top_clients.collect do |client,count|
      client.id
    end
    chart_data = @project.issued_invoices.where(["client_id IN (#{client_ids.join(',')}) and date > ?", 5.years.ago]).group(:client_id).group_by_month(:date, format: "%Y/%m").sum('total_in_cents/100')
    final_json = JSON.parse(chart_data.chart_json)
    final_json.each do |h|
      client_id = h['name']
      client = Client.find client_id
      h['name'] = client.name if client
    end
    render json: final_json 
  end

end
