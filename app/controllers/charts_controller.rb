class ChartsController < ApplicationController

  before_action :find_project_by_project_id
  before_action :find_optional_client, :only => [:invoice_status, :update_chart_preference]
  before_action :authorize, :except => [:invoice_total, :update_chart_preference]
  include ChartsHelper
  helper :haltr

  accept_api_auth :invoice_total, :invoice_status, :top_clients, :cash_flow

  def invoice_total
    chart_data = []
    pref = params[:pref] || User.current.pref.others[:chart_invoice_total]
    currencies = @project.issued_invoices.group(:currency).count.keys
    currencies.each do |currency|
      projdata = @project.issued_invoices
      projdata = projdata.where("currency = ?", currency)
      case pref
      when "all_by_year"
        projdata = projdata.where(["date > ?", 7.years.ago]).
          group_by_year(:date, format: "%Y").sum('total_in_cents/100')
      when "last_month_by_week"
        projdata = projdata.where(["date > ?", 1.month.ago]).
          group_by_week(:date, format: "%Y/%W").sum('total_in_cents/100')
      when "all_by_month"
        projdata = projdata.where(["date > ?", 7.years.ago]).
          group_by_month(:date, format: "%Y/%m").sum('total_in_cents/100')
      else # last_year_by_month
        projdata = projdata.where(["date > ?", 1.years.ago]).
          group_by_month(:date, format: "%Y/%m").sum('total_in_cents/100')
      end
      chart_data << {
        name: currency,
        data: projdata
      }
    end
    respond_to do |format|
      format.json { render json: chart_data.chart_json  }
      format.xml  { render xml: JSON.parse(chart_data.chart_json) }
    end
  end

  def invoice_status
    pref = params[:pref] || User.current.pref.others[:chart_invoice_status]
    if @client
      invoices = @client.issued_invoices
    else
      invoices = @project.issued_invoices
    end
    if params[:currency]
      invoices = invoices.where("currency = ?", params[:currency])
    end
    case pref
    when "all_by_year"
      projdata = invoices.where(["date > ?", 7.years.ago]).group(:state).
        group_by_year(:date, format: "%Y").sum('total_in_cents/100')
    when "last_month_by_week"
      projdata = invoices.where(["date > ?", 1.month.ago]).group(:state).
        group_by_week(:date, format: "%Y/%W").sum('total_in_cents/100')
    when "all_by_month"
      projdata = invoices.where(["date > ?", 7.years.ago]).group(:state).
        group_by_month(:date, format: "%Y/%m").sum('total_in_cents/100')
    else # last_year_by_month
      projdata = invoices.where(["date > ?", 1.years.ago]).group(:state).
        group_by_month(:date, format: "%Y/%m").sum('total_in_cents/100')
    end
    chart_data = projdata
    final_json = JSON.parse(chart_data.chart_json)
    final_json.each do |h|
      state_key = h['name']
      h['name'] = l("state_#{state_key}")
    end
    respond_to do |format|
      format.json { render json: final_json }
      format.xml  { render xml: final_json }
    end
  end

  def top_clients
    top_clients = @project.issued_invoices.where(["date > ?", 5.years.ago])
    if params[:currency]
      top_clients = top_clients.where("currency = ?", params[:currency])
    end
    top_clients = top_clients.group(:client).limit(5).order("sum_total_in_cents_100 DESC").sum('total_in_cents/100')
    client_ids = top_clients.collect do |client,count|
      client.id
    end
    where = client_ids.any? ?  "client_id IN (#{client_ids.join(',')}) and date > ?" : "date > ?"
    pref = params[:pref] || User.current.pref.others[:chart_top_clients]
    invoices = @project.issued_invoices
    if params[:currency]
      invoices = invoices.where("currency = ?", params[:currency])
    end
    case pref
    when "all_by_year"
      chart_data = invoices.where([where, 7.years.ago]).
        group(:client_id).group_by_year(:date, format: "%Y").
        sum('total_in_cents/100')
    when "last_month_by_week"
      chart_data = invoices.where([where, 1.month.ago]).
        group(:client_id).group_by_week(:date, format: "%Y/%m/%d").
        sum('total_in_cents/100')
    when "all_by_month"
      chart_data = invoices.where([where, 7.years.ago]).
        group(:client_id).group_by_month(:date, format: "%Y/%m").
        sum('total_in_cents/100')
    else # last_year_by_month
      chart_data = invoices.where([where, 1.year.ago]).
        group(:client_id).group_by_month(:date, format: "%Y/%m").
        sum('total_in_cents/100')
    end
    final_json = JSON.parse(chart_data.chart_json)
    final_json.each do |h|
      client_id = h['name']
      client = Client.find client_id
      h['name'] = client.name if client
    end
    respond_to do |format|
      format.json { render json: final_json }
      format.xml  { render xml: final_json }
    end
  end

  def cash_flow
    respond_to do |format|
      format.api do
        pref = params[:pref] || User.current.pref.others[:chart_cashflow]
        @due_invoices     = {}
        @invoices         = {}
        @due_invoices_sum = {}
        @invoices_sum     = {}
        @currencies = @project.issued_invoices.group(:currency).count.keys
        @currencies.each do |currency|
          @due_invoices[currency]     = invoices_past_due(@project, pref, currency)
          @invoices[currency]         = invoices_on_schedule(@project, pref, currency)
          @due_invoices_sum[currency] = Money.new(@due_invoices[currency].sum('total_in_cents'), currency)
          @invoices_sum[currency]     = Money.new(@invoices[currency].sum('total_in_cents'), currency)
        end
      end
    end
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

  def find_optional_client
    if params[:client] and client = Client.find(params[:client])
      @client = client
    end
  end

end
