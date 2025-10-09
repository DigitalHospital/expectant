# frozen_string_literal: true

RSpec.describe Expectant::Configuration do
  subject(:configuration) { described_class.new }

  describe "#initialize" do
    it "sets default validator_prefix to nil" do
      expect(configuration.validator_prefix).to be_nil
    end

    it "sets default validator_suffix to 'rule'" do
      expect(configuration.validator_suffix).to eq("rule")
    end
  end

  describe "#validator_prefix" do
    it "can be set to a custom value" do
      configuration.validator_prefix = "validate"
      expect(configuration.validator_prefix).to eq("validate")
    end

    it "can be set to nil" do
      configuration.validator_prefix = "custom"
      configuration.validator_prefix = nil
      expect(configuration.validator_prefix).to be_nil
    end
  end

  describe "#validator_suffix" do
    it "can be set to a custom value" do
      configuration.validator_suffix = "validation"
      expect(configuration.validator_suffix).to eq("validation")
    end

    it "can be set to nil" do
      configuration.validator_suffix = nil
      expect(configuration.validator_suffix).to be_nil
    end
  end
end
