# frozen_string_literal: true

require "dry-types"

module Expectant
  module Types
    include Dry.Types()

    # Convenience method to map symbol shortcuts to dry-types
    def self.resolve(type_definition)
      case type_definition
      when nil
        # No type specified, use Any
        Any
      when Symbol
        resolve_symbol(type_definition)
      when Array
        # Handle nested array syntax: [:array, :string] or [:array, CustomClass]
        if type_definition.first == :array && type_definition.size == 2
          Array.of(resolve(type_definition[1]))
        else
          raise ArgumentError, "Invalid array type definition: #{type_definition}"
        end
      when Dry::Types::Type
        # Already a dry-type, return as-is
        type_definition
      when Class
        # Custom class - use Instance type
        Instance(type_definition)
      else
        raise ArgumentError, "Invalid type definition: #{type_definition}"
      end
    end

    def self.resolve_symbol(symbol)
      case symbol
      when :string, :str
        Params::String
      when :integer, :int
        Params::Integer
      when :float
        Params::Float
      when :decimal
        Params::Decimal
      when :boolean, :bool
        Params::Bool
      when :date
        Params::Date
      when :datetime
        Params::DateTime
      when :time
        Params::Time
      when :array
        Params::Array
      when :hash
        Params::Hash
      when :symbol, :sym
        Symbol
      when :any
        Any
      when :nil
        Params::Nil
      else
        raise ArgumentError, "Unknown type symbol: #{symbol}"
      end
    end
  end
end
