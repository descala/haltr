module ChartsHelper

  def haltr_projects
    user = User.current
    projs = []
    if @project and ( user.admin? or user.projects.include?(@project) )
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

  def invoices_past_due(project,from=nil)
    case from.to_s
    when 'last_year'
      project.issued_invoices.where(["state != 'closed' and due_date < ? and date >= ?", Date.today, 1.year.ago])
    when 'last_3_months'
      project.issued_invoices.where(["state != 'closed' and due_date < ? and date >= ?", Date.today, 3.months.ago])
    else
      project.issued_invoices.where(["state != 'closed' and due_date < ?", Date.today])
    end
  end

  def invoices_on_schedule(project,from=nil)
    case from
    when 'last_year'
      project.issued_invoices.where(["state != 'closed' and due_date >= ? and date >= ?", Date.today, 1.year.ago])
    when 'last_3_months'
      project.issued_invoices.where(["state != 'closed' and due_date >= ? and date >= ?", Date.today, 3.months.ago])
    else
      project.issued_invoices.where(["state != 'closed' and due_date >= ?", Date.today])
    end
  end

end
