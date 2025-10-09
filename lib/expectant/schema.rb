# frozen_string_literal: true

require "dry/validation"

module Expectant
  class Schema
    attr_reader :name, :fields, :validators

    def initialize(name)
      @name = name
      @fields = []
      @validators = []
      @contract_class = nil
    end

    def keys
      @fields.map(&:name)
    end

    def contract
      @contract_class ||= build_contract
    end

    def duplicate
      dup = self.class.new(@name)
      dup.instance_variable_set(:@fields, @fields.dup)
      dup.instance_variable_set(:@validators, @validators.dup)
      dup
    end

    def add_field(expectation)
      @fields << expectation
      @contract_class = nil
    end

    def add_validator(validator_def)
      @validators << validator_def
      @contract_class = nil
    end

    def freeze
      @fields.freeze
      @validators.freeze
      super
    end

    def reset!
      @fields = []
      @validators = []
      @contract_class = nil
    end

    private

    def build_contract
      fields = @fields
      validators = @validators

      Class.new(Dry::Validation::Contract) do
        # Enable option passing (allows context and instance to be passed at validation time)
        option :context, default: proc { {} }
        option :instance, optional: true

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

        # Add custom validators
        validators.each do |validator_def|
          if validator_def[:name]
            # Single key or multiple keys
            if validator_def[:name].is_a?(Array)
              rule(*validator_def[:name], &validator_def[:block])
            else
              rule(validator_def[:name], &validator_def[:block])
            end
          else
            # Global rule without a specific field
            rule(&validator_def[:block])
          end
        end
      end
    end
  end
end
