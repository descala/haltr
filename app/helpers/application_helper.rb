# -*- coding: utf-8 -*-
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def custom_value(project,custom_field_name,alt="")
    project.custom_value_for(ProjectCustomField.find_by_name(custom_field_name.to_s)).value rescue alt
  end

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
      "Last used: #{InvoiceDocument.last_number}"
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
  
  def euros(import)
    if import && import.cents != 0
      "#{import}€"
    else
      "-"
    end
  end
  
  def quantity(q)
    if q.floor == q
      q.to_i
    else
      number_with_delimiter q, :delimiter => ".", :separator => ","
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
