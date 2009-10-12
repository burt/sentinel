module Sentinel
  module Controller

    def self.included(base)
      base.class_inheritable_writer :sentinel, :instance_writer => false
      base.class_inheritable_accessor :access_denied, :access_granted

      base.send :include, InstanceMethods
      base.extend ClassMethods

      base.class_eval do
        helper_method :sentinel
      end

      base.on_denied_with do
        respond_to do |format|
          format.html do
            render  :text => "You do not have the proper privileges to access this page.",
                    :status => :unauthorized
          end
          format.any  { head :unauthorized }
        end
      end

      base.with_access do
        true
      end
    end

    module InstanceMethods
      def sentinel
        self.instance_eval(&self.class.sentinel)
      end
    end

    module ClassMethods
      # Macro to add restful access control by convention
      def restful_access_control
        model_name = self.name.demodulize.gsub("Controller", "").singularize.downcase.to_sym
        controls_access_with do
          model = instance_variable_get "@#{model_name}"
          "#{model_name.to_s.capitalize}Sentinel".constantize.new :current_user => current_user, model_name => model
        end
        self.grants_access_to :index, :only => [:index]
        self.grants_access_to :create, :only => [:new, :create]
        self.grants_access_to :read, :only => [:show]
        self.grants_access_to :update, :only => [:edit, :update]
        self.grants_access_to :destroy, :only => [:destroy]
      end
      
      def controls_access_with(&block)
        self.sentinel = block
      end

      def sentinel
        read_inheritable_attribute(:sentinel)
      end

      def on_denied_with(name = :default, &block)
        self.access_denied ||= {}
        self.access_denied[name] = block
      end

      def with_access(&block)
        self.access_granted = block
      end

      def grants_access_to(*args, &block)
        options = args.extract_options!

        block = args.shift if args.first.respond_to?(:call)
        sentinel_method = args.first
        denied_handler = options.delete(:denies_with) || :default

        before_filter(options) do |controller|
          if block
            if (block.arity == 1 ? controller.sentinel : controller).instance_eval(&block)
              controller.instance_eval(&controller.class.access_granted)
            else
              controller.instance_eval(&controller.class.access_denied[denied_handler])
            end
          elsif sentinel_method && controller.sentinel && controller.sentinel.send(sentinel_method)
            controller.instance_eval(&controller.class.access_granted)
          else
            controller.instance_eval(&controller.class.access_denied[denied_handler])
          end
        end
      end
    end
  end
end
