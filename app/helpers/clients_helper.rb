module ClientsHelper
  def client_payment_method_info(client)
    if client.debit?
      # IssuedInvoice + debit, show clients iban
      if client.use_iban?
        iban = client.iban || ""
        bic  = client.bic || ""
        s="#{l(:debit_str)} IBAN: #{iban.scan(/.{1,4}/).join(' ')}"
        s+=" BIC: #{bic}" unless bic.blank?
        s
      else
        ba = client.bank_account || ""
        "#{l(:debit_str)} #{ba[0..3]} #{ba[4..7]} #{ba[8..9]} #{ba[10..19]}"
      end
    elsif client.transfer? and client.bank_info
      "#{l(:transfer_str)} #{client.bank_info.name}"
    elsif client.special?
      client.payment_method_text
    elsif client.cash?
      l(:cash_str)
    end.html_safe
  end

  def client_terms(client)
    Terms.new(client.terms).description.downcase
  end
end
