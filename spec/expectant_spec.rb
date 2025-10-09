# frozen_string_literal: true

RSpec.describe Expectant do
  it "has a version number" do
    expect(Expectant::VERSION).not_to be nil
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(Expectant.configuration).to be_a(Expectant::Configuration)
    end

    it "returns the same instance on multiple calls" do
      config1 = Expectant.configuration
      config2 = Expectant.configuration
      expect(config1).to equal(config2)
    end
  end

  describe ".configure" do
    after do
      Expectant.reset_configuration!
    end

    it "yields the configuration object" do
      expect { |b| Expectant.configure(&b) }.to yield_with_args(Expectant.configuration)
    end

    it "allows setting configuration options" do
      Expectant.configure do |config|
        config.validator_prefix = "validate"
        config.validator_suffix = "constraints"
      end

      expect(Expectant.configuration.validator_prefix).to eq("validate")
      expect(Expectant.configuration.validator_suffix).to eq("constraints")
    end
  end

  describe ".reset_configuration!" do
    it "resets the configuration to defaults" do
      Expectant.configure do |config|
        config.validator_prefix = "custom"
        config.validator_suffix = "custom_suffix"
      end

      Expectant.reset_configuration!

      expect(Expectant.configuration.validator_prefix).to be_nil
      expect(Expectant.configuration.validator_suffix).to eq("rule")
    end

    it "creates a new Configuration instance" do
      original_config = Expectant.configuration
      Expectant.reset_configuration!
      new_config = Expectant.configuration

      expect(new_config).not_to equal(original_config)
      expect(new_config).to be_a(Expectant::Configuration)
    end
  end
end
