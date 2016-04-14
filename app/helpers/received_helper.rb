module ReceivedHelper
  def font_size(attributes)
    [attributes[:y1].to_i-attributes[:y0].to_i-1, 9].max
  end
  def invoice_imgs_context_menu(url)
    unless @context_menu_included
      content_for :header_tags do
        javascript_include_tag('invoice_imgs_context_menu', :plugin => 'haltr') +
          stylesheet_link_tag('context_menu')
      end
      if l(:direction) == 'rtl'
        content_for :header_tags do
          stylesheet_link_tag('context_menu_rtl')
        end
      end
      @context_menu_included = true
    end
    javascript_tag "contextMenuInit('#{ url_for(url) }')"
  end
end
