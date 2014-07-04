module ChartsHelper

  def haltr_projects
    user = User.current
    projs = []
    if user.admin? and @project
      projs << @project
    else
      user.projects.each do |project|
        if project.module_enabled? :haltr and user.allowed_to?(:general_use, project) and project.company
          if projs.size >= 5
            flash.now[:error] = "Too many projects to display (showing 5)"
            break
          end
          projs << project
        end
      end
    end
    projs
  end

  def invoices_past_due(project)
    project.issued_invoices.where(["state != 'closed' and due_date < ?", Date.today])
  end

  def invoices_on_schedule(project)
    project.issued_invoices.where(["state != 'closed' and due_date >= ?", Date.today])
  end

end
