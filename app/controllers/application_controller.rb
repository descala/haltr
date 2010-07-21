# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'utils'

begin

  require 'redmine'
  RAILS_DEFAULT_LOGGER.info 'Running inside Redmine, it has its own ApplicationController'

rescue MissingSourceFile

  RAILS_DEFAULT_LOGGER.info 'Running standalone'

  class ApplicationController < ActionController::Base
    unloadable
    helper :all # include all helpers, all the time
    protect_from_forgery # See ActionController::RequestForgeryProtection for details
    # Scrub sensitive parameters from your log
    filter_parameter_logging :password
    layout 'default'
  end

end
