module ReceivedHelper
  def font_size(attributes)
    [attributes[:y1].to_i-attributes[:y0].to_i-1, 9].max
  end
end
