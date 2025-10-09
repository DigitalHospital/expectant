# frozen_string_literal: true

RSpec.describe "Expectant Error Classes" do
  describe Expectant::Error do
    it "is a StandardError" do
      expect(described_class).to be < StandardError
    end

    it "can be raised with a message" do
      expect { raise described_class, "test error" }.to raise_error(described_class, "test error")
    end

    it "can be caught as StandardError" do
      expect do
        raise described_class, "test"
      rescue => e
        expect(e).to be_a(described_class)
      end.not_to raise_error
    end
  end

  describe Expectant::ConfigurationError do
    it "is an Expectant::Error" do
      expect(described_class).to be < Expectant::Error
    end

    it "can be raised with a message" do
      expect do
        raise described_class, "invalid configuration"
      end.to raise_error(described_class, "invalid configuration")
    end

    it "can be caught as Expectant::Error" do
      expect do
        raise described_class, "test"
      rescue Expectant::Error => e
        expect(e).to be_a(described_class)
      end.not_to raise_error
    end
  end

  describe Expectant::SchemaError do
    it "is an Expectant::Error" do
      expect(described_class).to be < Expectant::Error
    end

    it "can be raised with a message" do
      expect do
        raise described_class, "schema error"
      end.to raise_error(described_class, "schema error")
    end

    it "can be caught as Expectant::Error" do
      expect do
        raise described_class, "test"
      rescue Expectant::Error => e
        expect(e).to be_a(described_class)
      end.not_to raise_error
    end
  end

  describe Expectant::ValidationError do
    it "is an Expectant::Error" do
      expect(described_class).to be < Expectant::Error
    end

    it "can be raised with a message" do
      expect do
        raise described_class, "validation failed"
      end.to raise_error(described_class, "validation failed")
    end

    it "can be caught as Expectant::Error" do
      expect do
        raise described_class, "test"
      rescue Expectant::Error => e
        expect(e).to be_a(described_class)
      end.not_to raise_error
    end
  end

  describe "error hierarchy" do
    it "allows catching all Expectant errors" do
      errors_caught = []

      [
        Expectant::Error,
        Expectant::ConfigurationError,
        Expectant::SchemaError,
        Expectant::ValidationError
      ].each do |error_class|
        raise error_class, "test"
      rescue Expectant::Error => e
        errors_caught << e.class
      end

      expect(errors_caught.size).to eq(4)
    end

    it "allows specific error handling" do
      raise Expectant::ConfigurationError, "config error"
    rescue Expectant::ConfigurationError => e
      expect(e.message).to eq("config error")
    rescue Expectant::Error
      fail "Should have caught ConfigurationError specifically"
    end
  end
end
