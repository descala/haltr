require 'net/imap'

# Available IMAP options:
#  host      IMAP server host (default: 127.0.0.1)
#  port      IMAP server port (default: 143)
#  ssl       Use SSL? (default: false)
#  username  IMAP account
#  password  IMAP password
#  folder    IMAP folder to read (default: INBOX)
#  message   The email message

module Haltr
  module IMAP
    class << self
      def store_draft(imap_options={})
        host = imap_options[:host] || '127.0.0.1'
        port = imap_options[:port] || '143'
        ssl = !imap_options[:ssl].nil?
        folder = imap_options[:folder] || 'INBOX/Drafts'
        imap = Net::IMAP.new(host, port, ssl)
        imap.login(imap_options[:username], imap_options[:password]) unless imap_options[:username].nil?
        imap.append(folder, imap_options[:message].to_s.gsub(/\n/, "\r\n"), [:Draft], Time.now)
      end

      private

      def logger
        Rails.logger
      end
    end
  end
end
