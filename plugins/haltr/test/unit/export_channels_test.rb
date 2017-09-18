require File.dirname(__FILE__) + '/../test_helper'

class ExportChannelsTest < ActiveSupport::TestCase

  test "returns a duplicate of the options object" do
    channel = 'pdf_by_mail'
    ExportChannels.use_file('channels.yml.example')
    options = ExportChannels.options(channel)
    assert_equal({'foo'=>'bar'},options)
    # This new element should not be returned next time
    # options should be a duplicate of the Hash object
    options['a'] = 1
    options = ExportChannels.options(channel)
    assert_equal({'foo'=>'bar'},options)
    ExportChannels.use_file('channels.yml')
  end

end
