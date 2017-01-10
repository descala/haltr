module CompanyFilter



  def check_for_company
    if @project.company.nil?
      user_mail = User.find_by_project_id(@project.id).mail rescue ""
      c = Company.new(:project=>@project,
                      :name=>@project.name,
                      :email=>user_mail)
      if ExportChannels.available? Setting.plugin_haltr['default_invoice_format']
        c.invoice_format = Setting.plugin_haltr['default_invoice_format']
      else
        c.invoice_format = 'paper'
      end
      c.save(:validate=> false)
      @project.reload
    end
    unless @project.company.valid?
      message = "#{l(:halt_configure_before_use, href: view_context.link_to(l(:company_href), project_my_company_path(@project)))}<br/>#{@project.company.errors.full_messages.join('<br/>')}".html_safe
      flash.now[:error] = message
      if User.current.admin?
        flash.now[:error] = message
      else
        flash[:error] = message
        redirect_to :controller => :companies, :action => :my_company, :project_id => @project
      end
    end
  end

end
