module Sentinel
  class Sentinel
    def initialize(*args)
      attributes = args.extract_options!
      attributes.keys.each do |key|
        create_accessor_for_attribute(key)
        self.send("#{key}=", attributes[key]) if self.respond_to?("#{key}=")
      end
    end

    def [](temporary_overrides)
      temporary_overrides.keys.each do |key|
        create_accessor_for_attribute(key)
      end

      returning self.clone do |duplicate|
        temporary_overrides.keys.each do |key|
          if self.respond_to?("#{key}=")
            duplicate.send("#{key}=", temporary_overrides[key])
          end
        end
      end
    end
    
    # Adds an authorisation scope to the associated model
    def self.auth_scope(name, block)
      model_class = self.name.demodulize.gsub("Sentinel", "").constantize
      model_class.send :named_scope, name.to_sym, block
    end
    
    # TODO: move this helper to class
    # source: http://blog.jayfields.com/2008/02/ruby-dynamically-define-method.html
    def self.def_each(*method_names, &block)
      method_names.each do |method_name|
        define_method method_name do
          instance_exec method_name, &block
        end
      end
    end
    
    # Adds rest methods, returning false in each case
    def_each :index, :create, :read, :update, :destroy do |method_name|
      false
    end

    private

    def create_accessor_for_attribute(attribute)
      unless self.respond_to?(attribute) || self.respond_to?("#{attribute}=")
        self.class_eval { attr_accessor attribute }
      end
    end
  end
end
