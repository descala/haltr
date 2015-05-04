# encoding: utf-8
module Haltr::ExportableDocument

  def self.included(base)
    base.class_eval do

      ExportChannels.validators.each do |validator|
        # prevent duplicate errors when including same module several times
        unless base.ancestors.include? validator
          # include validators from channel
          base.send(:include, validator)
        end
      end

      def sending_info(channel_name=nil)
        if state == 'processing_pdf'
          return 'in process...'
        end
        channel_name ||= self.client.invoice_format rescue nil
        channel = ExportChannels.available[channel_name.to_s]
        format = nil
        lang=""
        recipients = nil
        if channel
          format = channel["locales"][I18n.locale.to_s]
          if channel.has_key?("validators") and channel["validators"].to_a.include? "Haltr::Validator::Mail"
            recipients = "\n#{self.recipient_emails.join("\n")}"
          end
          if channel["format"] == "pdf" and self.client and self.client.language != User.current.language
            lang=" (#{l(:general_lang_name, :locale=>self.client.language)})"
          end
        else
          format = "Can't find channel #{channel_name}, please check channels.yml"
        end
        if channel["format"] == "pdf" and self.client and self.client.language != User.current.language
          lang=" (#{l(:general_lang_name, :locale=>self.client.language)})"
        end
        "#{format}#{lang}<br/>#{errors.full_messages.join(', ')}<br/>#{recipients}".html_safe
      end

    end
  end

end

