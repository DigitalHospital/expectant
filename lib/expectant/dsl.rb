# frozen_string_literal: true

module Expectant
  module DSL
    def self.extended(base)
      base.class_eval do
        @schemas = {}
        @schema_definitions = {}
      end
    end

    # Define a new schema type (e.g., :expects, :promises, :params, :outputs)
    def expectation(schema_name)
      schema_name = schema_name.to_sym
      (@schema_definitions ||= {})[schema_name] = {
        fields: [],
        rules: []
      }

      # Dynamically define the field definition method (e.g., expects, promises)
      define_singleton_method(schema_name) do |name, **options|
        expectation = Expectation.new(name, **options)
        @schema_definitions[schema_name][:fields] << expectation

        # Define attribute accessor
        attr_accessor name

        expectation
      end

      # Dynamically define the rule method (e.g., expects_rule, promises_rule)
      rule_method_name = "#{schema_name}_rule"
      define_singleton_method(rule_method_name) do |*field_names, &block|
        @schema_definitions[schema_name][:rules] << {
          name: field_names.empty? ? nil : (field_names.size == 1 ? field_names.first : field_names),
          block: block
        }
      end
    end

    # Get the schema definition for a given schema name
    def schema_definitions
      @schema_definitions ||= {}
    end

    # Build and return a dry-schema for a specific schema type
    def get_schema(schema_name)
      schema_name = schema_name.to_sym
      (@schemas ||= {})[schema_name] ||= SchemaBuilder.new(
        schema_definitions[schema_name]
      ).build
    end

    # Validate data against a specific schema
    def validate(schema_name, data)
      get_schema(schema_name).call(data)
    end

    def new(*args, **kwargs)
      instance = super(*args, **kwargs)

      # Set default values for all schema fields
      schema_definitions.each do |_schema_name, definition|
        definition[:fields].each do |expectation|
          if expectation.default
            default_value = expectation.default.respond_to?(:call) ?
                           expectation.default.call :
                           expectation.default
            instance.send("#{expectation.name}=", default_value)
          end
        end
      end

      instance
    end
  end
end