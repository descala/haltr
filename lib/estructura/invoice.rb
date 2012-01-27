# encoding: utf-8
require 'estructura'

module Estructura
  class Invoice < Dataset

    R_DATE = /\d{1,4}[-\/\.]\d{1,4}[-\/\.]\d{1,4}/

    # Examples:
    #  ESB00000000
    TAX_ID = /\b([a-z][ -]{0,3}\d{8}|[\d\.]{8,10}[ -]{0,3}[a-z]|[a-z][ -]{0,3}\d{7}[ -]{0,3}[a-z]|[a-z]{2,3}\d{8,9})\b/i

    def initialize(doc,options={})
      super(doc)
      @my_own_tax_id = options[:tax_id] # VAT ID del destinatari
    end

    def apply_rules
      tag [:tax_rate, :percentual], /%/, :number => true, :depth => 2
      tag :tax_rate, /i\.?v\.?a|v\.?a\.?t/, :number => true, :depth => 2, :extra => /\d+\s*%|\d{1,2}[.,]0{1,2}/
      tag :amount, /\b[+-]?\d+[\.,]*\b/, :exact => true
      tag :total_amount, /\b[+-]?\d+[\.,]\d+\b/, :exact => true, :weight => 5
      tag :total_amount, /total|amount/, :import => true, :depth => 3, :extra => /^(\342\202\254)*[\$\€\s]*[+-]?\s*\d+[\.,\d]*[\$\s]*(\342\202\254)*$/i
      tag :total_amount, /base impo[a-z]+ble/, :weight => 5, :import => true, :depth => 3, :extra => /^(\342\202\254)*[\$\€\s]*[+-]?\s*\d+[\.,\d]*[\$\s]*(\342\202\254)*$/i
      tag :tax_identification_number, /tva\s+id|vat\s+n/
      tag :tax_identification_number, /[nc].*i.*f/
      tag :tax_identification_number, /\bCVR\b/
      tag :tax_identification_number, TAX_ID, :exact => true, :weight => 20, :extra => /\d{8}[ -]{0,3}[A-Z]/
      tag :invoice_number, /n.mero de factura|factura\s|factura.*:|factura\s+n|^\W*n:|number|n.mero id|invoice|n.mero\s+factura|n.m\.?\s+factura|n.m\./, :number => true, :extra => /^[\d\W]+$/
      tag :invoice_number, /^\s*(factura\s+n|^\W*n:|number|n.mero id|invoice|n.mero\s+factura|n.m\.?\s+factura)\s*[\d\W]+$/, :number => true, :weight => 20
      tag [:issue_date, :due_date], R_DATE, :exact => true
      tag :issue_date, /data\.*factura/, :number => true, :weight => 40, :score_less => /\bvencim/i
      tag :issue_date, /fecha|data|date/, :number => true, :depth => 2, :score_less => /\bvencim/i, :extra => R_DATE
      tag :issue_date, /^(fecha|data|date)$/, :number => true, :weight => 20, :score_less => /\bvencim/i
      tag :due_date, /vencim|due.*date/, :number => true
      tag :due_date, /pagament/, :number => true
      tag :withholding_tax, /i.?r.?p.?f|retenci/, :number => true
    end

    def tax_rate(options={})
      exclude = options[:exclude]
      exclude = [] unless exclude.is_a? Array
      return @tax_rate if @tax_rate and !exclude.include?(@tax_rate)
      @tax_rate = pick_tax(:tax_rate,:exclude=>exclude)
      @tax_rate
    end

    def total_amount(options={})
      exclude = options[:exclude]
      exclude = [] unless exclude.is_a? Array
      return @total_amount if @total_amount and !exclude.include?(@total_amount) and !options[:nocache]
      highest_token = nil
      highest_tokens_for_tag(:total_amount,:depth=>2).each do |t|
        next if exclude.include?(t.to_i_str)
        highest_token = t if highest_token.nil?
        # agafem el que estigui mes avall
        highest_token = t if t.y > highest_token.y and t.to_i_str =~ /[+-]?[\.\,\d]+$/
      end
      if highest_token.nil?
        tokens_for_tag(:total_amount).each do |t|
          next if exclude.include?(t.to_i_str)
          highest_token = t if highest_token.nil?
          # agafem el que estigui mes avall
          highest_token = t if t.y > highest_token.y and t.to_i_str =~ /[+-]?[\.\,\d]+$/
        end
      end
      @total_amount = highest_token.nil? ? "" : highest_token.to_i_str
      @total_amount
    end

    def tax_identification_number
      return @tax_identification_number if @tax_identification_number
      highest_token = nil
      highest_tokens_for_tag(:tax_identification_number,:depth=>2).each do |t|
        highest_token = t unless my_own_tax_id?(t.str)
      end
      if highest_token.nil?
        tokens_for_tag(:tax_identification_number).each do |t|
          highest_token = t unless my_own_tax_id?(t.str)
        end
      end
      result = highest_token.nil? ? "" : highest_token.str.scan(TAX_ID).to_s
      if result.size > 0 or highest_token.nil?
        @tax_identification_number = result
      else
        @tax_identification_number = highest_token.str.scan(/\d{7,8}/i).to_s
      end
      @tax_identification_number
    end

    def invoice_number
      return @invoice_number if @invoice_number
      highest_token = nil
      highest_tokens_for_tag(:invoice_number).each do |t|
        highest_token = t if highest_token.nil?
        highest_token = t unless Utils.seems_date?(t.str)
      end
      @invoice_number = highest_token.nil? ? "" : highest_token.str.gsub(/(factura.*n|number|invoice|º|[\W\s]*:)\s*/i,'').gsub(/factura\s*/i,'')
      @invoice_number
    end

    def issue_date
      @issue_date ||= pick_date(:issue_date)
      @issue_date
    end

    def due_date
      @due_date ||= pick_date(:due_date)
      @due_date
    end

    def withholding_tax
      @withholding_tax ||= pick_tax(:withholding_tax)
      @withholding_tax
    end

    def amounts
      return @amounts if @amounts
      @amounts = tokens_for_tag(:amount).collect { |t|
        v = t.to_i_str ; v if v.size > 0
      }.compact
      @amounts
    end

    def possible_total_amounts(options={})
      return @possible_total_amounts if @possible_total_amounts and !options[:nocache]
      @possible_total_amounts = []
      amounts.each do |a|
        val = a.to_f
        wt = 0
        t = 0
        if withholding_tax.size > 0
          wt = val * withholding_tax.to_f / 100
        end
        if tax_rate.size > 0
          t = val * tax_rate.to_f / 100
        end
        val = val - wt + t
        @possible_total_amounts << ((val * 100).round / 100.0)
      end
      @possible_total_amounts
    end

    def valid_total_amount?
      return possible_total_amounts.include?(total_amount.to_f) ||
             possible_total_amounts.include?(total_amount.to_f + 0.01) ||
             possible_total_amounts.include?(total_amount.to_f - 0.01)
    end

    def fix_amounts
      wrong_tax_rates = []
      wrong_tax_rates << withholding_tax if withholding_tax.size > 0
      while (tax_rate(:exclude=>wrong_tax_rates) != "" and !valid_total_amount?) do
        wrong_total_amounts = []
        possible_total_amounts(:nocache=>true)
        while (total_amount(:exclude=>wrong_total_amounts,:nocache=>true) != "") do
          return true if valid_total_amount?
          wrong_total_amounts << total_amount
        end
        wrong_tax_rates << tax_rate unless valid_total_amount?
      end
      unless valid_total_amount? or @retried
        @tokens = extract_tokens(true)
        apply_rules
        @retried = true
        @amounts = nil
        @tax_rate = nil
        @withholding_tax = nil
        @invoice_number = nil
        @tax_identification_number = nil
        fix_amounts
      end
      return valid_total_amount?
    end

    def my_own_tax_id?(tax_id)
      if @my_own_tax_id.is_a? Regexp
        return !(tax_id =~ @my_own_tax_id).nil?
      elsif @my_own_tax_id.is_a? String
        nums = @my_own_tax_id.scan(/\d+/).first
        char = @my_own_tax_id.scan(/[a-z]/i).first
        regexp = Regexp.new("#{char}[\s\-]{0,3}#{nums}")
        regexp2 = Regexp.new("#{nums}[\s\-]{0,3}#{char}")
        return (!(tax_id =~ regexp).nil? or !(tax_id =~ regexp2).nil?)
      end
      return false
    end

    private

    def pick_date(tag_name)
      highest_token = nil
      highest_tokens_for_tag(tag_name).each do |t|
        highest_token = t if Utils.seems_date? t.str
      end
      result = highest_token.nil? ? "" : Utils.parse_date(highest_token.str).strftime("%d/%m/%Y")
      unless result.size > 0
        tokens_for_tag(tag_name).each do |t|
          highest_token = t if Utils.seems_date? t.str
        end
        result = highest_token.nil? ? "" : Utils.parse_date(highest_token.str).strftime("%d/%m/%Y")
      end
      result
    end

    def pick_tax(tag_name,options={})
      exclude = options[:exclude]
      exclude = [] unless exclude.is_a? Array
      highest_token = nil
      highest_tokens_for_tag(tag_name).each do |t|
        next if exclude.include? t.to_i_str or
                exclude.include? Utils.string_to_number(t.str.scan(/[+-]?[\.\,\d]+\s*%/).to_s.gsub(/[% ]/,''))
        # un percentatge ha de tenir 1 o 2 xifres, i possiblement decimals
        next unless t.str =~ /\b\d{1,2}\b/ or t.str =~ /\b\d{1,2}[\.,]{1}\d+\b/
        highest_token = t if highest_token.nil?
        curr_tv = highest_token.tag_value(:percentual) if highest_token
        tv      = t.tag_value(:percentual)
        next unless tv
        # agafem el que tingui el tag "percentual" mes alt
        highest_token = t if curr_tv.nil? or tv > curr_tv
      end
      if highest_token.nil?
        tokens_for_tag(tag_name).each do |t|
          next if exclude.include? t.to_i_str or
                  exclude.include? Utils.string_to_number(t.str.scan(/[+-]?[\.\,\d]+\s*%/).to_s.gsub(/[% ]/,''))
          # un percentatge ha de tenir 1 o 2 xifres, i possiblement decimals
          next unless t.str =~ /\b\d{1,2}\b/ or t.str =~ /\b\d{1,2}[\.,]{1}\d+\b/
            highest_token = t if highest_token.nil?
          curr_tv = highest_token.tag_value(:percentual) if highest_token
          tv      = t.tag_value(:percentual)
          next unless tv
          # agafem el que tingui el tag "percentual" mes alt
          highest_token = t if curr_tv.nil? or tv > curr_tv
        end
      end
      result = highest_token.nil? ? "" : Utils.string_to_number(highest_token.str.scan(/[+-]?[\.\,\d]+\s*%/).to_s.gsub(/[% ]/,''))
      return result if result.size > 0
      highest_token.nil? ? "" : highest_token.to_i_str
    end

  end
end
