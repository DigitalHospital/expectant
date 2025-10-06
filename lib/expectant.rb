# frozen_string_literal: true

require_relative "expectant/version"
require_relative "expectant/types"
require_relative "expectant/dsl"
require_relative "expectant/schema_builder"
require_relative "expectant/expectation"

module Expectant
  class Error < StandardError; end

  def self.included(base)
    base.extend(DSL)
  end
end
