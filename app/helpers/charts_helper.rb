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
    invoices = project.issued_invoices.
      joins('LEFT JOIN payments ON payments.invoice_id = invoices.id')
    case from.to_s
    when 'last_year'
      invoices = invoices.where(["state != 'closed' and due_date < ? and invoices.date >= ?", Date.today, 1.year.ago])
    when 'last_3_months'
      invoices = invoices.where(["state != 'closed' and due_date < ? and invoices.date >= ?", Date.today, 3.months.ago])
    else
      invoices = invoices.where(["state != 'closed' and due_date < ?", Date.today])
    end
    if currency
      invoices = invoices.where("currency = ?", currency)
    end
    invoices = invoices.where("state not in ('error', 'refused')")
    invoices
  end

  def invoices_past_due_path(project,from=nil)
    date_from = ''
    case from.to_s
    when 'last_year'
      date_from = 1.year.ago.to_date
    when 'last_3_months'
      date_from = 3.months.ago.to_date
    end
    project_invoices_path(:project_id=>project,new:1,sending:1,sent:1,discarded:1,registered:1,accepted:1,due_date_to:Date.yesterday,date_from:date_from,date_to:'')
  end

  def invoices_on_schedule(project,from=nil,currency=nil)
    invoices = project.issued_invoices.
      joins('LEFT JOIN payments ON payments.invoice_id = invoices.id')
    case from
    when 'last_year'
      invoices = invoices.where(["state != 'closed' and due_date >= ? and invoices.date >= ?", Date.today, 1.year.ago])
    when 'last_3_months'
      invoices = invoices.where(["state != 'closed' and due_date >= ? and invoices.date >= ?", Date.today, 3.months.ago])
    else
      invoices = invoices.where(["state != 'closed' and due_date >= ?", Date.today])
    end
    if currency
      invoices = invoices.where("currency = ?", currency)
    end
    invoices = invoices.where("state not in ('error', 'refused')")
    invoices
  end

  def invoices_on_schedule_path(project,from=nil)
    date_from = ''
    case from.to_s
    when 'last_year'
      date_from = 1.year.ago.to_date
    when 'last_3_months'
      date_from = 3.months.ago.to_date
    end
    project_invoices_path(:project_id=>project,new:1,sending:1,sent:1,discarded:1,registered:1,accepted:1,due_date_from:Date.today,date_from:date_from,date_to:'')
  end

end
