class ExportChannelsController < ApplicationController
  unloadable

  layout 'admin'
  menu_item :export_channels
  before_filter :require_admin
  helper :haltr

  def index
    @channels = ExportChannels.available.sort do |a,b|
      if a[1]['order'].blank? and b[1]['order'].blank?
        a[0].downcase <=> b[0].downcase
      elsif a[1]['order'].blank?
        1
      elsif b[1]['order'].blank?
        -1
      else
        a[1]['order'].to_i <=> b[1]['order'].to_i
      end
    end
  end

end
