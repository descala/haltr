class ChartsController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :only => [:invoice_status,:top_clients]
  before_filter :authorize, :except => [:invoice_total, :update_chart_preference]
  include ChartsHelper
  helper :haltr

  def invoice_total
    projects = haltr_projects
    if projects.any?
      chart_data = []
      projects.each do |project|
        case User.current.pref.others[:chart_invoice_total]
        when "all_by_year"
          projdata = project.issued_invoices.where(["date > ?", 7.years.ago]).
            group_by_year(:date, format: "%Y/%m").sum('total_in_cents/100')
        when "last_year_by_month"
          projdata = project.issued_invoices.where(["date > ?", 1.years.ago]).
            group_by_month(:date, format: "%Y/%m").sum('total_in_cents/100')
        when "last_month_by_week"
          projdata = project.issued_invoices.where(["date > ?", 1.month.ago]).
            group_by_week(:date, format: "%Y/%m").sum('total_in_cents/100')
        else # all_by_month
          projdata = project.issued_invoices.where(["date > ?", 7.years.ago]).
            group_by_month(:date, format: "%Y/%m").sum('total_in_cents/100')
        end
        chart_data << {
          name: project.company.name,
          data: projdata
        }
      end
      render json: chart_data.chart_json
    else
      render_404
    end
  end

  def invoice_status
    case User.current.pref.others[:chart_invoice_status]
    when "all_by_year"
      projdata = @project.issued_invoices.where(["date > ?", 7.years.ago]).
        group(:state).group_by_year(:date, format: "%Y/%m").sum('total_in_cents/100')
    when "last_year_by_month"
      projdata = @project.issued_invoices.where(["date > ?", 1.years.ago]).
        group(:state).group_by_month(:date, format: "%Y/%m").sum('total_in_cents/100')
    when "last_month_by_week"
      projdata = @project.issued_invoices.where(["date > ?", 1.month.ago]).
        group(:state).group_by_week(:date, format: "%Y/%m").sum('total_in_cents/100')
    else # all_by_month
      projdata = @project.issued_invoices.where(["date > ?", 7.years.ago]).
        group(:state).group_by_month(:date, format: "%Y/%m").sum('total_in_cents/100')
    end
    chart_data = projdata
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
    if client_ids.any?
      chart_data = @project.issued_invoices.where(["client_id IN (#{client_ids.join(',')}) and date > ?", 5.years.ago]).group(:client_id).group_by_month(:date, format: "%Y/%m").sum('total_in_cents/100')
    else
      chart_data = @project.issued_invoices.where(["date > ?", 5.years.ago]).group(:client_id).group_by_month(:date, format: "%Y/%m").sum('total_in_cents/100')
    end
    final_json = JSON.parse(chart_data.chart_json)
    final_json.each do |h|
      client_id = h['name']
      client = Client.find client_id
      h['name'] = client.name if client
    end
    render json: final_json
  end

  def update_chart_preference
    name=params[:name]
    value=params[:value]
    if name and value and name =~ /^chart/
      preference=User.current.preference
      preference.others[name.to_sym]=value
      preference.save
    end
    @chart_name=name
    respond_to do |format|
      format.js
    end
  end
end
