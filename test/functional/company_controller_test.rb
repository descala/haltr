# Redmine - project management software
# Copyright (C) 2008  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.dirname(__FILE__) + '/../test_helper'

class EmbeddedControllerTest < ActionController::TestCase
  fixtures :projects, :enabled_modules, :users, :roles, :members
  
  def setup
    fixtures_path = File.dirname(__FILE__) + '/../fixtures/html'
    
    Setting.plugin_embedded = { 'path' => fixtures_path,
                                'index' => 'main.html overview-summary.html index.html',
                                'extensions' => 'html png gif',
                                'template' => '',
                                'encoding' => '',
                                'menu' => 'Embedded' }
                                
    Project.find(1).enabled_modules << EnabledModule.new(:name => 'embedded')
    
    anonymous = Role.anonymous
    anonymous.permissions += [:view_embedded_doc]
    assert anonymous.save
  end
  
  def test_get_root_should_redirect_to_index_file
    get :index, :id => 'ecookbook'
    assert_redirected_to :path => ['index.html']
  end
  
  def test_get_index_file
    get :index, :id => 'ecookbook', :path => ['index.html']
    assert_response :success
    assert_template 'index'
    assert_tag :h3, :content => 'C0 code coverage information'
  end
  
  def test_get_subdirectory_file
    get :index, :id => 'ecookbook', :path => ['misc', 'misc.html']
    assert_response :success
    assert_template 'index'
    assert_tag :b, :content => 'Misc file'
  end
  
  def test_get_invalid_extension_should_be_denied
    get :index, :id => 'ecookbook', :path => ['misc', 'misc.txt']
    assert_response 500
  end
end
