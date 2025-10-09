# frozen_string_literal: true

module Expectant
  class Configuration
    attr_accessor :validator_prefix, :validator_suffix

    def initialize
      @validator_prefix = nil # default: no prefix
      @validator_suffix = "rule" # default: schema_name_rule
    end
  end
end
