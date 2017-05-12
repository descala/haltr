module Haltr
  module Import

    class Aeb43

      attr_accessor :text

      def initialize(file)
        if File.file?(file) and File.readable?(file)
          @text = open(file) do
            |f| f.read
          end 
        end
      end

      def moviments
        moviments=[]
        account = nil
        @text.each_line do |line|
          case line[0..1]
          when '11'
            account = line[2..22].to_s.strip
          when '22'
            moviments << Moviment.new(line, account)
          when '23' 
            moviments.last.process_23(line) rescue nil
          end
        end
        moviments
      end

      def to_s
        moviments.each do |m|
          m.to_s
        end
      end

    end


    class Moviment

      attr_accessor :date_o, :date_v, :positiu, :amount, :ref1, :ref2
      attr_accessor :txt1, :txt2
      attr_accessor :account

      def initialize(line,account=nil)
        @account = account
        process_22 line
      end

      def process_22(line)
        @line = line
        @date_o = aammdd_date 10
        @date_v = aammdd_date 16
        @amount = money 28, 13
        @ref1 = string 52, 11
        @ref2 = string 64, 16
        @positiu = signe 27
      end

      def process_23(line)
        @line = line
        @txt1 = string 4, 37
        @txt2 = string 42, 37 
      end

      def to_s
        s = positiu ?  '+' : '-'
        n = "#{s}#{amount}"
        t = "#{ref1} #{ref2} #{txt1} #{txt2}"
        "#{@date_o} #{date_v} #{n.rjust(14)} #{t.strip}" 
      end

      private

      attr_accessor :line

      def aammdd_date(pos)
        Date.strptime(line[pos..pos+6], '%y%m%d') rescue nil
      end
      def money(pos,len)
        Money.new(line[pos..pos+len].to_i, Money::Currency.new(Setting.plugin_haltr['default_currency']))
      end
      def string(pos,len)
        line[pos..pos+len].to_s.strip
      end
      def signe(pos)
        signe = true  # haver
        signe = false if line[pos..pos] == '1' # debe
        signe
      end
    end

  end
end
