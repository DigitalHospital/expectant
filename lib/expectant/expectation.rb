# frozen_string_literal: true

module Expectant
  class Expectation
    attr_reader :name, :type, :optional, :default

    def initialize(name, type: nil, optional: false, default: nil, **options)
      @name = name
      @type = type
      @optional = optional
      @default = default
      @options = options
    end

    def required?
      !optional && default.nil?
    end

    def has_default?
      !default.nil?
    end

    def type_class
      case type
      when :integer, :int
        Integer
      when :float
        Float
      when :string, :str
        String
      when :boolean, :bool
        [TrueClass, FalseClass]
      when :array
        Array
      when :hash
        Hash
      when Class
        type
      else
        nil
      end
    end

    def dry_validation_type
      case type
      when :integer, :int
        :integer
      when :float
        :float
      when :string, :str
        :string
      when :boolean, :bool
        :bool
      when :array
        :array
      when :hash
        :hash
      when Class
        # For custom classes, we'll use :any and add custom validation
        :any
      else
        :any
      end
    end
  end
end