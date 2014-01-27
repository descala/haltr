desc "For all Client and Company, calculate iban from bank_account"

namespace :haltr do
  task :ccc2iban do |task, args|
    puts "Migratin CCC to IBAN ..."
    Client.all.each do |client|
      ccc = client.bank_account
      unless ccc.blank?
        country = client.country
        if client.country != 'es'
          puts "[#{client.taxcode}] Skiping non spanish CCC (#{country} #{ccc})"
        else
          if !BankInfo.valid_spanish_ccc?(ccc)
            puts "[#{client.taxcode}] Skiping invalid CCC (#{ccc})"
          else
            iban = BankInfo.local2iban('ES',ccc)
            if IBANTools::IBAN.valid?(client.iban) and client.iban != iban
              puts "[#{client.taxcode}] already has a valid IBAN #{client.iban}"
            else
              if client.iban != iban
                puts "[#{client.taxcode}] #{ccc} => #{iban}"
                client.iban = iban
                client.save!
              end
            end
          end
        end
      end
    end
  end
end


