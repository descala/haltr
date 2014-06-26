module ChartsHelper

  def haltr_projects
    user = User.current
    user.projects.collect do |project|
      project if project.module_enabled? :haltr and user.allowed_to?(:general_use, project)
    end.compact
  end

end
