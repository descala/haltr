desc "Import clients CSV data. Usage: rake haltr:import:clients['project_name','clients.csv']"

namespace :haltr do
  namespace :import do
    task :clients, [:project_id, :file] => :environment do |task, args|

      args.with_defaults(:file => 'clients.csv')

      begin
        puts "project_id = #{args[:project_id]}"
        project = Project.find args[:project_id]
        clients_file = args[:file]
        puts "Project = #{project}"
        puts "Clients file = #{clients_file}"
        puts "===================================="
        STDOUT.flush

        include CsvImporter

        process_clients(:project => project, :file_name => clients_file)

      rescue => error
        puts "Error: #{error}"
        raise error
      end
    end
  end
end

desc "Import invoices CSV data. Usage: rake haltr:import:invoices['project_name','invoices.csv']"

namespace :haltr do
  namespace :import do
    task :invoices, [:project_id, :file] => :environment do |task, args|

      args.with_defaults(:file => 'invoices.csv')

      begin
        puts "project_id = #{args[:project_id]}"
        project = Project.find args[:project_id]
        invoices_file = args[:file]
        puts "Project = #{project}"
        puts "invoices file = #{invoices_file}"
        puts "===================================="
        STDOUT.flush

        include CsvImporter

        process_invoices(:project => project, :file_name => invoices_file)

      rescue => error
        puts "Error: #{error}"
        raise error
      end
    end
  end
end


desc "Import Dir3Entities from csv. Usage: rake haltr:import:dir3['dir3_entities.csv']"

namespace :haltr do
  namespace :import do

    task :dir3, [:entities] => :environment do |task, args|

      args.with_defaults(:entities=>'dir3_entities.csv')

      begin
        puts "Entities to import:  #{args[:entities]}"
        puts "===================================="
        STDOUT.flush

        include CsvImporter

        process_dir3entities(:entities  => args[:entities])

      rescue => error
        puts "Error: #{error}"
        raise error
      end
    end

  end
end

desc "Import ExternalCompanies from csv. Usage: rake haltr:import:external_companies['external_companies.csv']"

namespace :haltr do
  namespace :import do

    task :external_companies, [:external_companies] => :environment do |task, args|

      args.with_defaults(:external_companies=>'external_companies.csv')

      begin
        puts "External Companies file: #{args[:external_companies]}"
        puts "===================================="
        STDOUT.flush

        include CsvImporter

        process_external_companies(:external_companies => args[:external_companies])

      rescue => error
        puts "Error: #{error}"
        raise error
      end
    end

  end
end

