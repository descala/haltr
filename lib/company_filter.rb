module CompanyFilter

  unloadable

  def check_for_company
    if @project.company.nil?
      c = Company.new(:project=>@project,:name=>@project.name)
      c.save(:validate=> false)
      @project.reload
    end
    unless @project.company.valid?
      flash[:error] = l(:halt_configure_before_use)
      unless User.current.admin?
        redirect_to :controller => :companies, :action => :my_company, :project_id => @project
      end
    end
  end

end
