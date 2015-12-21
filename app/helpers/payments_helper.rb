# encoding: utf-8
module PaymentsHelper

  def invoices_for_select
    candidate_states = "('sent','registered','accepted')"
    if @payment.invoice
      cond = ["(project_id = ? and state in #{candidate_states}) OR invoices.id=?", @project, @payment.invoice]
    else
      cond = ["project_id = ? and state in #{candidate_states}", @project]
    end
    invoices_for_select = {I18n.t("IssuedInvoice")=>[],I18n.t("ReceivedInvoice")=>[]}
    @project.invoices.where(cond).order('number DESC').collect do |c|
      next unless invoices_for_select.keys.include?(I18n.t(c.type)) # DraftInvoice
      invoices_for_select[I18n.t(c.type)] << [ "#{c.number} #{c.total.to_s.rjust(10).gsub(' ','_')}€ #{c.client}", c.id ]
    end
    invoices_for_select
  end

  def n19_fix(string,n=40)
    string.to_ascii[0..n-1].upcase.ljust(n).html_safe
  end

end
