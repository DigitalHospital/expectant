# frozen_string_literal: true

require_relative "expectant/version"
require_relative "expectant/errors"
require_relative "expectant/configuration"
require_relative "expectant/types"
require_relative "expectant/dsl"
require_relative "expectant/expectation"

module Expectant
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
