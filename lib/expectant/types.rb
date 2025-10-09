# frozen_string_literal: true

require "dry-types"

module Expectant
  module Types
    include Dry.Types()

    def self.resolve(type_definition)
      case type_definition
      when nil
        Any
      when Symbol
        resolve_symbol(type_definition)
      when Dry::Types::Type
        # Already a dry-type, return as-is
        type_definition
      when Class
        Instance(type_definition)
      else
        raise ConfigurationError, "Invalid type definition: #{type_definition}"
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
      when :any, :nil
        Any
      else
        raise ConfigurationError, "Unknown type symbol: #{symbol}"
      end
    end
  end
end
