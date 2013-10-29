module CompanyFilter

  unloadable

  def check_for_company
    if @project.company.nil?
      user_mail = User.find_by_project_id(@project.id).mail rescue ""
      c = Company.new(:project=>@project,
                      :name=>@project.name,
                      :email=>user_mail)
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
