desc "Moves Event#file to a new Attachment"

namespace :haltr do
  task :event_file_to_attachment => :environment do |task, args|

    begin

      # http://guides.rubyonrails.org/active_record_querying.html#retrieving-multiple-objects-in-batches
      Event.find_each do |e|
        next if e.project.nil?
        next if e.read_attribute(:file).blank?
        a = Attachment.new
        a.file = StringIO.new e.file_old
        a.author = e.user || User.anonymous
        a.filename = e.filename || 'unknown_filename'
        a.created_on = e.created_at
        a.description = "Event #{e.id}"
        e.attachments << a
        puts "Attachment e=#{e.id} a=#{a.id} #{a.diskfile}"
        begin
          e.save!
        rescue exception
          puts e.errors.messages
          raise exception
        end
      end

    rescue => error
      puts "Error: #{error}"
      raise error
    end
  end
end
