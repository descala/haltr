class ReceivedOrder < Order
  unloadable

  after_create :notify_users_by_mail, if: Proc.new {|o|
    o.project.company.order_notifications
  }

  private

  def visible?(usr=nil)
    (usr || User.current).allowed_to?(:use_orders, project)
  end

  def notify_users_by_mail
    MailNotifier.order_add(self).deliver
  end

  def updated_on
    updated_at
  end

end
