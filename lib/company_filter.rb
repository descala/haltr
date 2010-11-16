module CompanyFilter

  unloadable

  def check_for_company
    Project.send(:include, ProjectHaltrPatch) #TODO: perque nomes funciona el primer cop sense aixo?
    return true unless @project.company.nil?
    c = Company.new(:project=>@project)
    c.save(false)
  end

end
