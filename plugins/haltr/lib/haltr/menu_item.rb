# Class to highlight multi-level menus
# it is a menu item with an array instead of a name
# Usage, in a controller:
#
#  menu_item Haltr::MenuItem.new(:companies,:my_company)
#
module Haltr
  class MenuItem
    def initialize(*args)
      @items = args
    end

    # select for any of our items
    def ==(current_menu_item)
      @items.include? current_menu_item
    end

    def to_sym
      @items.first.to_sym
    end

    def to_s
      @items.first
    end

  end
end
