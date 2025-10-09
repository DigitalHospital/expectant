# frozen_string_literal: true

module Expectant
  # Instance-bound schema wrapper that provides validation with instance context
  class BoundSchema
    def initialize(instance, schema)
      @instance = instance
      @schema = schema
    end

    def validate(data, context: {})
      # Apply proc defaults before validation
      data = apply_defaults(data)

      # Create contract instance with context, then validate
      contract_class = @schema.contract
      contract = contract_class.new(instance: @instance, context: context)
      result = contract.call(data)

      # If validation failed, apply fallbacks for fields with errors and retry
      if !result.success?
        data_with_fallbacks = apply_fallbacks(data, result)
        if data_with_fallbacks != data
          # Re-validate with fallback values
          result = contract.call(data_with_fallbacks)
        end
      end

      result
    end

    def keys
      @schema.keys
    end

    def contract
      @schema.contract
    end

    private

    # Apply default values for missing fields (especially proc defaults)
    def apply_defaults(data)
      data = data.dup

      @schema.fields.each do |field|
        # Skip if value already provided
        next if data.key?(field.name)

        # Apply proc defaults, static defaults are handled by dry-types
        if field.default.respond_to?(:call)
          data[field.name] = @instance.instance_exec(&field.default)
        end
      end

      data
    end

    # Apply fallback values to fields that have errors
    def apply_fallbacks(data, result)
      data = data.dup

      @schema.fields.each do |field|
        next unless field.has_fallback?

        # Apply fallback if field has an error
        if result.errors[field.name]&.any?
          fallback_value = if field.fallback.respond_to?(:call)
            # Proc fallback - evaluate in instance context
            @instance.instance_exec(&field.fallback)
          else
            field.fallback
          end
          data[field.name] = fallback_value
        end
      end

      data
    end
  end
end
