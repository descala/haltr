module ChartsHelper

  def haltr_projects
    user = User.current
    projs = []
    user.projects.each do |project|
      if project.module_enabled? :haltr and user.allowed_to?(:general_use, project) and project.company
        if projs.size >= 5
          flash.now[:error] = "Too many projects to display (showing 5)"
          break
        end
        projs << project
      end
    end
    projs
  end

end
