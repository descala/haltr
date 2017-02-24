class CreditsController < ApplicationController

  layout 'haltr'

  before_filter :find_project_by_project_id

  def index
    @entries = []
    @entries << @project.company.buy_account.credit_entries
    @entries << @project.company.free_ocr_account.credit_entries
    @entries << @project.company.ocr_account.credit_entries
    @entries << @project.company.free_issues_account.credit_entries
    @entries << @project.company.issues_account.credit_entries
    @entries.flatten!
  end

  def create
    amount = params[:amount].to_f
    if amount > 0
      Plutus::Entry.create!(
        description: "Paid recharge",
        date: Date.today,
        debits: [{account: @project.company.recharge_account, amount: amount}],
        credits: [{account: @project.company.buy_account, amount: amount}]
      )
    end
    redirect_to project_credits_path(project_id: @project)
  end

end
