# frozen_string_literal: true

require "dry/validation"

module Expectant
  class SchemaBuilder
    def initialize(schema_definition)
      @fields = schema_definition[:fields]
      @rules = schema_definition[:rules]
    end

    def build
      fields = @fields
      rules = @rules

      Class.new(Dry::Validation::Contract) do
        # Enable option passing (allows context to be passed at validation time)
        option :context, default: proc { {} }

        # Define schema based on fields using dry-types
        params do
          fields.each do |field|
            dry_type = field.dry_type

            if field.required?
              required(field.name).value(dry_type)
            else
              optional(field.name).value(dry_type)
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
      end
    end
  end
end
