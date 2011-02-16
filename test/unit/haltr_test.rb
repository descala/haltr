require File.dirname(__FILE__) + '/../test_helper'

class HaltrTest < ActiveSupport::TestCase

  def setup
    Setting.plugin_haltr = { 'trace_url' => 'loclhost:3000',
                             'export_channels_path' => '/tmp',
                             'menu' => 'Haltr' }
  end
  
end
