module Roles::Base
  def valid_roles_are(*role_list)
    strategy_class.valid_roles = role_list.to_symbols
  end
end

module Roles::ActiveRecord  
  def self.included(base) 
    base.extend Roles::Base
    base.extend ClassMethods
    base.orm_name = :active_record
  end

  module ClassMethods      

    def valid_single_strategies
      [:admin_flag, :one_role, :role_string]
    end

    def valid_multi_strategies
      [:many_roles, :roles_mask, :role_strings]
    end

    def strategies_with_role_class
      [:one_role, :many_roles]
    end 

    def valid_strategies
      valid_single_strategies + valid_multi_strategies
    end
    
    def strategy name, options = {}
      strategy_name = name.to_sym
      raise ArgumentError, "Unknown role strategy #{strategy_name}" if !valid_strategies.include? strategy_name
      use_roles_strategy strategy_name
            
      set_role_class(strategy_name, options) if strategies_with_role_class.include? strategy_name

      # one_role reference
      if strategy_name == :one_role
        self.belongs_to :one_role, :foreign_key => 'role_id', :class_name => @role_class_name.to_s
      end
      
      # many_roles references
      if strategy_name == :many_roles
        user_roles_class = options[:user_roles_class] if options.kind_of? Hash 
        user_roles_class ||= 'user_roles'
      
        instance_eval %{
          has_many :many_roles, :through => :#{user_roles_class}, :source => :#{@role_class_name.to_s.underscore}
          has_many :#{user_roles_class}
        }
      end
      
      set_role_strategy name, options
    end    
    
    private

    def set_role_class strategy_name, options = {}
      @role_class_name = !options.kind_of?(Symbol) ? get_role_class(strategy_name, options) : default_role_class(strategy_name)
    end

    def statement code_str
      code_str.gsub /Role/, @role_class_name.to_s
    end

    def default_role_class strategy_name
      if defined? ::Role
        require "roles_active_record/#{strategy_name}"
        return ::Role 
      end
      raise "Default Role class not defined"
    end
    
    def get_role_class strategy_name, options
      options[:role_class] ? options[:role_class].to_s.camelize.constantize : default_role_class(strategy_name)
    end
  end
end
