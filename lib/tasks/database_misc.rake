desc "Moves Event#file to a new Attachment"

namespace :haltr do
    task :event_file_to_attachment => :environment do |task, args|

      begin

        Event.all.each do |e|
          next if e.read_attribute(:file).blank?
          a = Attachment.new
          a.file = StringIO.new e.file_old
          a.author = e.user || User.anonymous
          a.filename = e.filename
          a.created_on = e.created_at
          a.description = "Event #{e.id}"
          e.attachments << a
          e.save!
          puts "Attachment e=#{e.id} a=#{a.id} #{a.filename}"
        end
 
      rescue => error
        puts "Error: #{error}"
        raise error
      end
    end
end


