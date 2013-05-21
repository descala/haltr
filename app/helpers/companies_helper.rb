module CompaniesHelper

  def contact_us_for_cif
    if defined?(SupportController)
      content_tag("span",:class=>'lineErrorExplanation') do
        l(:contact_us_for_cif,:link=>link_to(l(:contact_us),:controller=>'support',:action=>'new',:project_id=>@project))
      end
    end
  end

end
