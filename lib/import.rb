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
      @text.each_line do |line|
        case line[0..1]
        when '22'
          moviments << Moviment.new(line)
        when '23' 
          moviments.last.process_23 line
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
    
    def initialize(line)
      process_22 line
    end

    def process_22(line)
      @line = line
      @date_o = aammdd_date 10
      @date_v = aammdd_date 16
      @amount = money 28, 14
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
      "#{@date_o} #{date_v} #{s}#{amount} #{ref1} #{ref2} ** #{txt1} #{txt2}"
    end
    
    private
    
    attr_accessor :line
    
    def aammdd_date(pos)
      Date.strptime(line[pos..pos+6], '%y%m%d')
    end
    def money(pos,len)
      Money.create_from_cents(line[pos..pos+len].to_i)
    end
    def string(pos,len)
      line[pos..pos+len].strip
    end
    def signe(pos)
      signe = true  # haver
      signe = false if line[pos..pos] == '1' # debe
      signe
    end
  end

  
end
