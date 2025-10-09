# frozen_string_literal: true

module Expectant
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class SchemaError < Error; end
  class ValidationError < Error; end
end
