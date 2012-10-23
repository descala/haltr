# Include hook code here
ActiveSupport::Dependencies.load_once_paths.delete(lib_path)
require "iso_countries"
