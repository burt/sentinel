%w{ controller sentinel view_helper }.each do |f|
  require File.join(File.dirname(__FILE__), "sentinel", f)  
end

ActionController::Base.send :include, Sentinel::Controller
ActionView::Base.send :include, Sentinel::ViewHelper