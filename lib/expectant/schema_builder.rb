# frozen_string_literal: true

require 'dry/validation'

module Expectant
  class SchemaBuilder
    def initialize(schema_definition)
      @fields = schema_definition[:fields]
      @rules = schema_definition[:rules]
    end

    def build
      fields = @fields
      rules = @rules

      Dry::Validation.Contract do
        # Define schema based on fields
        params do
          fields.each do |field|
            if field.required?
              case field.dry_validation_type
              when :integer
                required(field.name).value(:integer)
              when :float
                required(field.name).value(:float)
              when :string
                required(field.name).value(:string)
              when :bool
                required(field.name).value(:bool)
              when :array
                required(field.name).value(:array)
              when :hash
                required(field.name).value(:hash)
              else
                required(field.name).filled
              end
            else
              case field.dry_validation_type
              when :integer
                optional(field.name).maybe(:integer)
              when :float
                optional(field.name).maybe(:float)
              when :string
                optional(field.name).maybe(:string)
              when :bool
                optional(field.name).maybe(:bool)
              when :array
                optional(field.name).maybe(:array)
              when :hash
                optional(field.name).maybe(:hash)
              else
                optional(field.name).value(:any)
              end
            end
          end
        end

        # Add custom rules
        rules.each do |rule_def|
          if rule_def[:name]
            # Single key or multiple keys
            if rule_def[:name].is_a?(Array)
              rule(*rule_def[:name], &rule_def[:block])
            else
              rule(rule_def[:name], &rule_def[:block])
            end
          else
            # Global rule without a specific field
            rule(&rule_def[:block])
          end
        end

        # Add type validation for custom classes
        fields.each do |field|
          next unless field.type.is_a?(Class)

          rule(field.name) do
            if value && !value.is_a?(field.type)
              key.failure("must be an instance of #{field.type}")
            end
          end
        end
      end
    end
  end
end