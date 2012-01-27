# encoding: utf-8
$KCODE = 'u'
require 'jcode' if RUBY_VERSION < '1.9'

require 'estructura/taggable'
require 'chronic'

module Estructura

  VERSION = '0.1'

  class Token
    include Taggable
    attr_reader :str, :x, :y, :size, :x1
    def initialize(str,x,y)
      @str = str
      @x = x
      @y = y
      @size = str.to_s.jsize
      @x1 = @x + @size - 1 if @x
    end
    def overlaps?(other)
      (@x..@x1).include?(other.x) || (@x..@x1).include?(other.x1) || (other.x..other.x1).include?(@x)
    end
    def ==(other)
      return false if other.nil?
      @str == other.to_s
    end
    def <=>(other)
      if @x == other.x
        @y <=> other.y
      else
        @x <=> other.x
      end
    end
    def to_s
      s = "\"#{@str}\" [#{@x},#{@y},#{@size}]"
      s += " =>" unless tags.empty?
      tags.each do |tag,value|
        s += " #{tag}(#{value})"
      end
      s
    end
    def to_i_str
      Utils.string_to_number(@str.scan(/[+-]?[\.\,\d]+\s*%?/).to_s.gsub(/[% ]/,''))
    end
    def =~(regexp)
      @str =~ regexp
    end
  end

  class Dataset

    attr_reader :document, :tokens

    def initialize(doc)
      # \302\240 is the Unicode sequence for non-breakable space
      @document = doc.gsub("\302\240",' ')
      @tokens = extract_tokens
    end

    def top_of(t)
      token = t.is_a?(Token) ? t : @tokens[t]
      candidates = []
      @tokens.each do |candidate|
        candidates << candidate if candidate.y < token.y and token.overlaps?(candidate)
      end
      candidates.reverse
    end

    def bottom_of(t)
      token = t.is_a?(Token) ? t : @tokens[t]
      candidates = []
      @tokens.each do |candidate|
        candidates << candidate if candidate.y > token.y and token.overlaps?(candidate)
      end
      candidates
    end

   def left_of(t)
      token = t.is_a?(Token) ? t : @tokens[t]
      candidates = []
      @tokens.each do |candidate|
        candidates << candidate if candidate.x < token.x and candidate.y == token.y
      end
      candidates.reverse
    end

   def right_of(t)
      token = t.is_a?(Token) ? t : @tokens[t]
      candidates = []
      @tokens.each do |candidate|
        candidates << candidate if candidate.x > token.x and candidate.y == token.y
      end
      candidates
    end

    def tokens_for_tag(tag)
      a = []
      @tokens.each do |token|
        value = token.tag_value(tag)
        a << token if value
      end
      a
    end

    # Returns all matches for a tag
    # The highest values at the end of the array
    def highest_tokens_for_tag(tag, options={})
      all_tokens = {}
      highest_tokens=[]
      tokens_for_tag(tag).each do |token|
        tv = token.tag_value(tag)
        all_tokens[tv] ||= []
        all_tokens[tv] << token
      end
      if all_tokens.any?
        keys = all_tokens.keys.sort
        depth = options[:depth].nil? ? 1 : options[:depth].to_i
        for i in 1..depth do
          highest_tokens << all_tokens[keys.pop]
        end
        highest_tokens.flatten.compact.reverse
      else
        []
      end
    end

    def tag(tags, rule, options={})
      r = []
      n = options[:weight] || 10
      depth = options[:depth].to_i > 1 ? options[:depth] : 1
      tags = [tags] unless tags.is_a?(Array)
      tags.each do |tag|
        if rule.is_a?(Regexp)
          # make rule case insensitive
          rule = Regexp.new(rule.source, rule.options|Regexp::IGNORECASE )
          @tokens.each do |token|
            if options[:number]
              next unless token =~ /\d+/
            end
            if options[:import]
              next unless Utils.seems_import?(token)
            end
            token.tag(tag,n) if token =~ rule
            if !options[:exact]
              left_tokens = left_of(token)
              top_tokens  = top_of(token)
              for d in 1..depth do
                token.tag(tag,n/(d+1)) if left_tokens[d-1] =~ rule
                token.tag(tag,n/(d+1)) if top_tokens[d-1]  =~ rule
              end
            end
            if options[:extra]
              token.increment_value(tag,n*2) if token =~ options[:extra]
            end
            if options[:score_less]
              token.decrement_value(tag,n*2) if token =~ options[:score_less]
            end
            r << token if token.tag_value(tag)
          end
        end
      end
      r
    end

    def to_s
      s = ''
      i = 0
      @tokens.each do |token|
        s += "#{i}. #{token.to_s}\n"
        i += 1
      end
      s
    end

    private

    def extract_tokens(one_space=false)
      tokens = []
      y = 0
      @document.each_line do |line|
        strings = one_space ? Utils.strings_one_space(line) : Utils.strings_two_spaces(line)
        strings.each do |str|
          x_not_unicode = line.rindex(str)
          x = line[0..x_not_unicode].jsize - 1
          tokens << Token.new(str,x,y)
        end
        y = y + 1
      end
      tokens
    end
  end

  module Utils
    def self.numbers(text)
      candidates = text.scan /([+-]?[\.\,\d]+)/
        candidates.collect do |n|
        n = n.join if n.is_a? Array
        n.to_f.zero? ? nil : n
        end.compact
    end
    def self.strings_one_space(text)
      text.split(/(\s{1,}|$)/).collect do |s|
        ss = s.strip
        ss.empty? ? nil : ss
      end.compact
    end
    def self.strings_two_spaces(text)
      text.split(/(\s{2,}|$)/).collect do |s|
        ss = s.strip
        ss.empty? ? nil : ss
      end.compact
    end
    def self.string_to_number(str)
      str = str.scan(/[^\d]*([-]?\d+(?:[\d\.,]*\d+)*)[^\d]*/).first.first rescue ""
      if str.split(',').size - 1 > 1 # mes d'una coma
        if str.split('.').size - 1 <= 1 # un o cap punt
          str.gsub(/,/,'')
        else # mes d'un punt
          ""
        end

      elsif str.split('.').size - 1 > 1 # mes d'un punt
        if str.split(',').size - 1 <= 1 # una o cap coma
          str.gsub(/\./,'').gsub(/,/,'.')
        else # mes d'una coma
          return ""
        end

      else # ni mes d'una coma ni mes d'un punt
        if str =~ /\..*,/ # punt despres coma
          str.gsub(/\./,'').gsub(/,/,'.')
        elsif str =~ /,.*\./ # coma despres punt
          str.gsub(/,/,'')
        else # una sola coma o un sol punt
          if str =~ /^\d{1,3}\.\d{3}$/ and !(str =~ /^0*\./) # sembla separador de milers
            str.gsub(/\./,'')
          else # deu ser separador de decimals
            str.gsub(/,/,'.')
          end
        end
      end
    end
    def self.seems_date?(str)
      !Utils.parse_date(str).nil?
    end
    def self.parse_date(str)
      return nil if str =~ /^\d+$/
      sep = "\\s?[\\._\/-]\\s?"
      # replace "._" with "/"
      date_str = str.gsub(/(\d+)(#{sep})(\d+)\2(\d+)/) { "#{$1}/#{$3}/#{$4}" }
      unless Chronic.parse(date_str, :endian_precedence => [:little, :middle]).nil?
        return Chronic.parse(date_str, :endian_precedence => [:little, :middle])
      end
      possible_results={}
      date_str.split.each do |substr|
        next if substr =~ /^\d+$/
        unless Chronic.parse(substr, :endian_precedence => [:little, :middle]).nil?
          possible_results[substr] = Chronic.parse(substr, :endian_precedence => [:little, :middle])
        end
      end
      pretty_one=nil
      possible_results.keys.each do |k|
        pretty_one = possible_results[k] if pretty_one.nil?
        pretty_one = possible_results[k] if k =~ /\d+(#{sep})\d+\1\d+/
      end
      return pretty_one
    end
    def self.seems_import?(str)
      cur = "((\342\202\254)|[\$\€])?\s?"
      str =~ /(\A|\s)#{cur}[+-]?\d+#{cur}(\Z|\s)/ or
      str =~ /(\A|\s)#{cur}[+-]?\d+[\.,]\d+#{cur}(\Z|\s)/ or
      str =~ /(\A|\s)#{cur}[+-]?\d+,\d+\.\d+#{cur}(\Z|\s)/ or
      str =~ /(\A|\s)#{cur}[+-]?\d+\.\d+,\d+#{cur}(\Z|\s)/
    end
  end

end

