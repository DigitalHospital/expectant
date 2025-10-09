# frozen_string_literal: true

require "active_support/inflector"

module Expectant
  module Utils
    module_function

    def singularize(word)
      ActiveSupport::Inflector.singularize(word.to_s).to_sym
    end

    def validator_method_name(schema_name, configuration)
      prefix = configuration.validator_prefix
      suffix = configuration.validator_suffix

      parts = []
      parts << prefix if prefix
      parts << schema_name
      parts << suffix if suffix

      parts.join("_")
    end

    def define_with_collision_policy(target, method_name, collision:, &block)
      method_name = method_name.to_sym
      if target.method_defined?(method_name) || target.private_method_defined?(method_name)
        case collision
        when :error
          raise ConfigurationError, "Method #{method_name} already defined"
        when :force
          begin
            target.send(:remove_method, method_name)
          rescue
            nil
          end
          block.call
        else
          raise ConfigurationError, "Unknown collision policy: #{collision}"
        end
      else
        block.call
      end
    end
  end
end
