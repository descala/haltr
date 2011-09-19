module CompaniesHelper

  def add_tax_link(company_form)
    link_to_function l(:button_add_tax), :class=>"icon icon-add" do |page|
      company_form.fields_for(:taxes, Tax.new, :child_index => 'NEW_RECORD') do |tax_form|
        html = render(:partial => 'companies/tax', :locals => { :f => tax_form })
        page << "$('taxes').insert({ bottom: '#{escape_javascript(html)}'.replace(/NEW_RECORD/g, new Date().getTime()) });"
      end
    end
  end

end
