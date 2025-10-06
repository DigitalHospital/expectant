# frozen_string_literal: true

module Expectant
  module DSL
    def self.extended(base)
      base.class_eval do
        @_expectant_schemas = {}
      end

      base.include(InstanceMethods)
    end

    # Define a new schema type
    def expectation(schema_name)
      schema_name = schema_name.to_sym
      @_expectant_schemas[schema_name] = {
        fields: [],
        rules: []
      }

      # Dynamically define the field definition method
      # (e.g. expects, promises, inputs, outputs)
      define_singleton_method(schema_name) do |name, **options|
        expectation = Expectation.new(name, **options)
        @_expectant_schemas[schema_name][:fields] << expectation

        expectation
      end

      # Add the rule definition method
      # (e.g. expects_rule, promises_rule, inputs_rule, outputs_rule)
      rule_method_name = "#{schema_name}_rule"
      define_singleton_method(rule_method_name) do |*field_names, &block|
        @_expectant_schemas[schema_name][:rules] << {
          name: if field_names.empty?
                  nil
                else
                  ((field_names.size == 1) ? field_names.first : field_names)
                end,
          block: block
        }
      end
    end

    # Get the schema definition for a given schema name
    def schema_definitions
      @_expectant_schemas ||= {}
    end

    # Build and return a dry-schema contract class for a specific schema type
    def get_schema(schema_name)
      schema_name = schema_name.to_sym
      (@schema_classes ||= {})[schema_name] ||= SchemaBuilder.new(
        schema_definitions[schema_name]
      ).build
    end

    # Get the field names (keys) for a specific schema
    def schema_keys(schema_name)
      schema_name = schema_name.to_sym
      definition = schema_definitions[schema_name]
      return [] unless definition

      definition[:fields].map(&:name)
    end

    # Instance methods module
    module InstanceMethods
      # Validate data against a specific schema
      # Options:
      #   context: Hash of values to make available inside rules (accessible via `context[:key]`)
      def validate(schema_name, data, context: {})
        schema_name = schema_name.to_sym

        # Apply proc defaults before validation
        data = apply_defaults(schema_name, data)

        # Create contract instance with context, then validate
        contract_class = self.class.get_schema(schema_name)
        contract = contract_class.new(context: context)
        result = contract.call(data)

        # If validation failed, apply fallbacks for fields with errors and retry
        if !result.success?
          data_with_fallbacks = apply_fallbacks(schema_name, data, result)
          if data_with_fallbacks != data
            # Re-validate with fallback values
            result = contract.call(data_with_fallbacks)
          end
        end

        result
      end

      private

      # Apply default values for missing fields (especially proc defaults)
      def apply_defaults(schema_name, data)
        data = data.dup
        definition = self.class.schema_definitions[schema_name]
        return data unless definition

        definition[:fields].each do |field|
          # Skip if value already provided
          next if data.key?(field.name)

          # Apply proc defaults
          if field.default.respond_to?(:call)
            data[field.name] = instance_exec(&field.default)
          end
          # Static defaults are handled by dry-types
        end

        data
      end

      # Apply fallback values to fields that have errors
      def apply_fallbacks(schema_name, data, result)
        data = data.dup
        definition = self.class.schema_definitions[schema_name]
        return data unless definition

        definition[:fields].each do |field|
          next unless field.has_fallback?

          # Apply fallback if field has an error
          if result.errors[field.name]&.any?
            fallback_value = if field.fallback.respond_to?(:call)
              # Proc fallback - evaluate in instance context
              instance_exec(&field.fallback)
            else
              # Static fallback
              field.fallback
            end
            data[field.name] = fallback_value
          end
        end

        data
      end
    end
  end
end
