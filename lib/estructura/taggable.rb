module Estructura
  module Taggable
    def tag(tag,value=1)
      @tags = Hash.new if @tags.nil?
      @tags[tag] = 0 if @tags[tag].nil?
      @tags[tag] += value.to_i
    end
    def tag_value(tag)
      return nil if @tags.nil?
      @tags[tag]
    end
    def tags
      return Hash.new if @tags.nil?
      @tags
    end
    def remove_tag(tag)
      @tags[tag]=nil
    end 
    def increment_value(tag,amount=10)
      return unless @tags and @tags[tag]
      @tags[tag] += amount.to_i
    end
    def decrement_value(tag,amount=10)
      return unless @tags and @tags[tag]
      @tags[tag] -= amount.to_i
      remove_tag(tag) if @tags[tag] <= 0
    end
  end
end
