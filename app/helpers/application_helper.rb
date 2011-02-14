# -*- coding: utf-8 -*-
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def path_to_stylesheet(source)
    path = super(source)
    especial path
  end

  def path_to_image(source)
    path = super(source)
    especial path
  end

  def environment
    e = ENV['RAILS_ENV']
    if e == 'production'
      content_tag :span, e, :style => 'color: red'
    else
      content_tag :span, e, :style => 'color: green'
    end
  end

  def number_form_column(record, input_name)
    output = input :record, :number, :class=>'text-input'
    output += content_tag :span do
      "Last used: #{IssuedInvoice.last_number(@project)}"
    end
  end

  # Renders flash messages
  def render_flash_messages
    s = ''
    flash.each do |k,v|
      s << content_tag('div', v, :class => "flash #{k}")
    end
    s
  end
  
  def money(import)
    number_to_currency(import, :unit => import.currency.symbol)
  end
  
  def quantity(q)
    if q.floor == q
      q.to_i
    else
      number_with_delimiter q, :delimiter => ".", :separator => ","
    end
  end

  def notify_pending_requests(project)
    if project.company.companies_with_link_requests.any?
      "<span style='color: #dd6600;'>(#{l(:pending_requests,:i=>project.company.companies_with_link_requests.size)})</span>"
    end
  end
  
  private
  
  def especial(path)
    if request.parameters["controller"] == "invoices" and request.parameters["action"] == "pdf" and !(path =~ /^https?:\/\//)
      "../public#{path}"
    else
      path
    end
  end
  
end
