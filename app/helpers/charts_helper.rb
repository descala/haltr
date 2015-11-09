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

  def invoices_past_due(project,from=nil,currency=nil)
    invoices = project.issued_invoices
    case from.to_s
    when 'last_year'
      invoices = invoices.where(["state != 'closed' and due_date < ? and date >= ?", Date.today, 1.year.ago])
    when 'last_3_months'
      invoices = invoices.where(["state != 'closed' and due_date < ? and date >= ?", Date.today, 3.months.ago])
    else
      invoices = invoices.where(["state != 'closed' and due_date < ?", Date.today])
    end
    if currency
      invoices = invoices.where("currency = ?", currency)
    end
    invoices
  end

  def invoices_on_schedule(project,from=nil,currency=nil)
    invoices = project.issued_invoices
    case from
    when 'last_year'
      invoices = invoices.where(["state != 'closed' and due_date >= ? and date >= ?", Date.today, 1.year.ago])
    when 'last_3_months'
      invoices = invoices.where(["state != 'closed' and due_date >= ? and date >= ?", Date.today, 3.months.ago])
    else
      invoices = invoices.where(["state != 'closed' and due_date >= ?", Date.today])
    end
    if currency
      invoices = invoices.where("currency = ?", currency)
    end
    invoices
  end

end
