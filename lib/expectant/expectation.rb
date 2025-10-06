# frozen_string_literal: true

module Expectant
  class Expectation
    attr_reader :name, :type, :dry_type, :fallback, :default

    def initialize(name, type: nil, default: nil, optional: false, fallback: nil, **options)
      @name = name
      @type = type
      @default = default
      @fallback = fallback
      @options = options

      base_type = Types.resolve(type)
      base_type = base_type.optional if optional
      # if default is a proc, we call it at runtime
      @dry_type = if !default.nil? && !default.respond_to?(:call)
        base_type.default(default)
      else
        base_type
      end
    end

    # A field is required if it's not optional and has no default
    def required?
      !@dry_type.optional? && !has_default?
    end

    def has_default?
      @dry_type.default? || !@default.nil?
    end

    def has_fallback?
      !@fallback.nil?
    end
  end
end
