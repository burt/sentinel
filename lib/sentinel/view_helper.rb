module Sentinel
    
  module ViewHelper
    
    # Adds a permitted_to? helper to dry up views
    def permitted_to?(action, opts)
      sentinel[opts].send action
    end
    
  end
    
end