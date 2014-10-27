desc "Import clients CSV data. Usage: rake haltr:import:clients['project_name','clients.csv']"

namespace :haltr do
  namespace :import do
    task :clients, [:project_id, :file] => :environment do |task, args|

      args.with_defaults(:file => 'clients.csv')

      begin
        project = Project.find args[:project_id]
        clients_file = args[:file]
        puts "Project = #{project}"
        puts "Clients file = #{clients_file}"
        puts "===================================="
        STDOUT.flush

        include CsvImporter

        process_clients(:project => project, :file_name => clients_file)

      rescue => error
        puts "Error: " + error
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
        project = Project.find args[:project_id]
        invoices_file = args[:file]
        puts "Project = #{project}"
        puts "Clients file = #{invoices_file}"
        puts "===================================="
        STDOUT.flush

        include CsvImporter

        process_invoices(:project => project, :file_name => invoices_file)

      rescue => error
        puts "Error: " + error
        raise error
      end
    end
  end
end

desc "Delete current Dir3 data and import new from csv. Usage: rake haltr:import:dir3['dir3_entities.csv','dir3_relations.csv']"

namespace :haltr do
  namespace :import do

    task :dir3, [:entities, :relations] => :environment do |task, args|

      args.with_defaults(:entities=>'dir3_entities.csv', :relations=>'dir3_relations.csv')

      begin
        puts "Entities to import:  #{args[:entities]}"
        puts "Relations to import: #{args[:relations]}"
        puts "===================================="
        STDOUT.flush

        include CsvImporter

        process_dir3entities(:entities  => args[:entities],
                             :relations => args[:relations])

      rescue => error
        puts "Error: #{error}"
        raise error
      end
    end

  end
end
