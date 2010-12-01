module CompanyFilter

  unloadable

  def check_for_company
    Project.send(:include, ProjectHaltrPatch) #TODO: perque nomes funciona el primer cop sense aixo?
    if @project.company.nil?
      c = Company.new(:project=>@project,:name=>@project.name.capitalize)
      c.save(false)
      @project.reload
    end
    unless @project.company.valid?
      flash[:error] = "Configure company settings before using haltr"
      redirect_to :controller => :companies, :action => :index, :id => @project
    end
  end

end
