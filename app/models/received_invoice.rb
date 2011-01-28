class ReceivedInvoice < Invoice

  unloadable

  # new sending sent error discarded closed
  state_machine :state, :initial => :validating_format do
    before_transition do |invoice,transition|
      unless Event.automatic.include?(transition.event.to_s)
        Event.create(:name=>transition.event.to_s,:invoice=>invoice,:user=>User.current)
      end
    end
    event :success_validating_format do
      transition :validating_format => :validating_signature
    end
    event :error_validating_format do
      transition :validating_format => :format_validation_error
    end
    event :success_validating_signature do
      transition :validating_signature => :accepted
    end
    event :error_validating_signature do
      transition :validating_signature => :signature_validation_error
    end
    event :pay do
      transition [:accepted,:format_validation_error,:signature_validation_error,:refused] => :paid
    end
    event :refuse do
      transition [:accepted,:format_validation_error,:signature_validation_error] => :refused
    end
  end

  def to_label
    "#{number}"
  end

end
