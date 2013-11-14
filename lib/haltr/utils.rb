module Haltr
  module Utils
    class << self

      def compress(string)
        return nil if string.nil?
        buf = ActiveSupport::Gzip.compress(string)
        Base64::encode64(buf).chomp
      end

      def decompress(string)
        return nil if string.nil?
        begin
          buf = Base64::decode64(string)
          ActiveSupport::Gzip.decompress(buf)
        rescue
          string
        end
      end

    end
  end
end
