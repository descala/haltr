module Haltr
  module PaymentMethods

    # 1 - cash (al comptat)
    # 2 - debit (rebut domiciliat)
    # 4 - transfer (transferència)
    PAYMENT_CASH     = 1
    PAYMENT_DEBIT    = 2
    PAYMENT_TRANSFER = 4
    PAYMENT_AWARDING = 7
    PAYMENT_CHEQUE   = 12
    PAYMENT_SPECIAL  = 13

    PAYMENT_CODES = {
      PAYMENT_CASH     => {:facturae => '01', :ubl => '10', :edifact => '10'},
      PAYMENT_DEBIT    => {:facturae => '02', :ubl => '49', :edifact => '42'},
      PAYMENT_TRANSFER => {:facturae => '04', :ubl => '31', :edifact => '31'},
      PAYMENT_AWARDING => {:facturae => '07', :ubl => '??', :edifact => ''  },
      PAYMENT_CHEQUE   => {:facturae => '12', :ubl => '??', :edifact => '20'},
      PAYMENT_SPECIAL  => {:facturae => '13', :ubl => '??', :edifact => ''  },
    }

    def payment_method=(v)
      if v =~ /_/
        write_attribute(:payment_method,v.split("_")[0])
        self.bank_info_id=v.split("_")[1]
      else
        write_attribute(:payment_method,v)
        self.bank_info=nil
      end
    end

    def payment_method
      if [PAYMENT_TRANSFER, PAYMENT_DEBIT].include?(read_attribute(:payment_method)) and bank_info
        "#{read_attribute(:payment_method)}_#{bank_info.id}"
      else
        read_attribute(:payment_method)
      end
    end

    def payment_method_code(format, attr=:payment_method)
      if PAYMENT_CODES[self[attr].to_i]
        PAYMENT_CODES[self[attr].to_i][format]
      end
    end

    # for transfer payment method it returns an entry for each bank_account on company:
    # ["transfer to <bank_info.name>", "<PAYMENT_TRANSFER>_<bank_info.id>"]
    # or one generic entry if there are no bank_infos on company:
    # ["transfer", PAYMENT_TRANSFER]
    def self.for_select(company)
      pm = [['---',''],[I18n.t("cash"), PAYMENT_CASH]]
      if company.bank_infos.any?
        tr = []
        db = []
        company.bank_infos.each do |bank_info|
          tr << [I18n.t("debit_through",:bank_account=>bank_info.name), "#{PAYMENT_DEBIT}_#{bank_info.id}"]
          db << [I18n.t("transfer_to",:bank_account=>bank_info.name),"#{PAYMENT_TRANSFER}_#{bank_info.id}"]
        end
        pm += tr
        pm += db
      else
        pm << [I18n.t("transfer"),PAYMENT_TRANSFER]
      end
      pm << [I18n.t("awarding"),PAYMENT_AWARDING]
      pm << [I18n.t("cheque"),PAYMENT_CHEQUE]
      pm << [I18n.t("other"),PAYMENT_SPECIAL]
    end

    def cash?
      read_attribute(:payment_method) == PAYMENT_CASH
    end

    def debit?
      read_attribute(:payment_method) == PAYMENT_DEBIT
    end

    def transfer?
      read_attribute(:payment_method) == PAYMENT_TRANSFER
    end

    def special?
      read_attribute(:payment_method) == PAYMENT_SPECIAL
    end

  end
end
