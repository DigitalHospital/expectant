# frozen_string_literal: true

require_relative "utils"
require_relative "schema"
require_relative "bound_schema"

module Expectant
  module DSL
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def self.extended(base)
        base.class_eval do
          @_expectant_schemas = {}
        end
      end

      def inherited(sub)
        return unless instance_variable_defined?(:@_expectant_schemas)
        return if @_expectant_schemas.empty?

        # Deep copy each schema (fields + validators)
        parent_schemas = @_expectant_schemas
        duped = parent_schemas.transform_values { |schema| schema.duplicate }

        sub.instance_variable_set(:@_expectant_schemas, duped)
      end

      # Define a new expectation schema
      # Options:
      #   collision: :error|:force -> method name collision policy for dynamic definitions
      #   singular: string|symbol  -> control singular name for the schema
      def expects(schema_name, collision: :error, singular: nil)
        field_method_name = Utils.singularize(schema_name.to_sym)
        if !singular.nil?
          if singular.is_a?(String) || singular.is_a?(Symbol)
            field_method_name = singular.to_sym
          else
            raise ConfigurationError, "Invalid singular option: #{singular.inspect}"
          end
        end
        schema = schema_name.to_sym

        if @_expectant_schemas.key?(schema)
          raise SchemaError, "Schema :#{schema} already defined"
        else
          create_schema(schema, collision: collision, field_method_name: field_method_name)
        end

        self
      end

      def reset_inherited_expectations!
        @_expectant_schemas = {}
      end

      private

      def create_schema(schema_name, collision: :error, field_method_name: nil)
        @_expectant_schemas[schema_name] = Schema.new(schema_name)

        # Dynamically define the field definition method
        # (e.g. input for :inputs, datum for :data)
        Utils.define_with_collision_policy(singleton_class, field_method_name, collision: collision) do
          define_singleton_method(field_method_name) do |name, **options|
            expectation = Expectation.new(name, **options)
            @_expectant_schemas[schema_name].add_field(expectation)
            expectation
          end
        end

        # Reset a schema
        reset_method_name = "reset_#{schema_name}!"
        Utils.define_with_collision_policy(singleton_class, reset_method_name, collision: collision) do
          define_singleton_method(reset_method_name) do
            @_expectant_schemas[schema_name].reset!
          end
        end

        # Define validators
        method_name = Utils.validator_method_name(field_method_name, Expectant.configuration)
        Utils.define_with_collision_policy(singleton_class, method_name, collision: collision) do
          define_singleton_method(method_name) do |*field_names, &block|
            @_expectant_schemas[schema_name].add_validator({
              name: if field_names.empty?
                      nil
                    else
                      ((field_names.size == 1) ? field_names.first : field_names)
                    end,
              block: block
            })
          end
        end

        # Add class-level schema accessor method (e.g. MyClass.inputs)
        Utils.define_with_collision_policy(singleton_class, schema_name, collision: collision) do
          define_singleton_method(schema_name) do
            @_expectant_schemas[schema_name]
          end
        end

        # Add instance-level schema accessor method (e.g. instance.inputs)
        if !instance_methods(false).include?(schema_name)
          define_method(schema_name) do
            BoundSchema.new(self, self.class.instance_variable_get(:@_expectant_schemas)[schema_name])
          end
        elsif collision == :force
          define_method(schema_name) do
            BoundSchema.new(self, self.class.instance_variable_get(:@_expectant_schemas)[schema_name])
          end
        elsif collision == :error
          raise ConfigurationError, "Instance method #{schema_name} already defined"
        end
      end
    end
  end
end
