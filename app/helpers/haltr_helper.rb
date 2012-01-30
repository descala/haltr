# Methods added to this helper will be available to all templates in the application.
module HaltrHelper

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

  # Renders flash messages
  def render_flash_messages
    s = ''
    flash.each do |k,v|
      s << content_tag('div', v, :class => "flash #{k}")
    end
    s
  end

  def money(import)
    currency = Money::Currency.new(import.currency)
    if currency.subunit_to_unit == 1
      number_to_currency(import, :unit => import.currency.symbol, :precision => 0)
    else
      number_to_currency(import, :unit => import.currency.symbol)
    end
  end

  def line_price(line)
    precision = line.price.to_s.split(".").last.size
    precision = 2 if precision == 1
    currency = Money::Currency.new(line.currency)
    if currency.subunit_to_unit == 1 and precision == 2
      precision = 0
    end
    number_to_currency(line.price, :unit => currency.symbol, :precision => precision)
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

  def self.currency_options_for_select
    opts = []
    Money::Currency::TABLE.each do |id,attributes|
      if attributes[:priority] && attributes[:priority] < 105
        opts << ["#{id.to_s.upcase} - #{attributes[:name]}",id.to_s.upcase]
      end
    end
    opts.compact.sort {|x,y|
      if x[1] == "EUR"
        -1
      elsif y[1] == "EUR"
        1
      elsif x[1] == "USD"
        -1
      elsif y[1] == "USD"
        1
      else
        x[0] <=> y[0]
      end
    }
  end

  def currency_options_for_select
    HaltrHelper.currency_options_for_select
  end

  def help(topic)
    content_tag("span",:class=>'help') do
      image_tag('help.png', :title => l(topic))
    end
  end

  private

  def especial(path)
    if @is_pdf and !(path =~ /^https?:\/\//)
      "../public#{path}"
    else
      path
    end
  end

end
