# frozen_string_literal: true

RSpec.describe Expectant::Expectation do
  describe "#initialize" do
    it "creates an expectation with basic attributes" do
      expectation = described_class.new(:name, type: :string)
      expect(expectation.name).to eq(:name)
      expect(expectation.type).to eq(:string)
    end

    it "accepts default value" do
      expectation = described_class.new(:status, type: :string, default: "pending")
      expect(expectation.default).to eq("pending")
    end

    it "accepts optional flag" do
      expectation = described_class.new(:description, type: :string, optional: true)
      expect(expectation.dry_type.optional?).to be true
    end

    it "accepts fallback value" do
      expectation = described_class.new(:count, type: :integer, fallback: 0)
      expect(expectation.fallback).to eq(0)
    end

    it "resolves type through Types.resolve" do
      expectation = described_class.new(:age, type: :integer)
      expect(expectation.dry_type).to be_a(Dry::Types::Type)
    end

    it "creates optional dry_type when optional: true" do
      expectation = described_class.new(:field, type: :string, optional: true)
      expect(expectation.dry_type.optional?).to be true
    end

    it "creates dry_type with default when default is not a proc" do
      expectation = described_class.new(:field, type: :string, default: "test")
      expect(expectation.dry_type.default?).to be true
    end

    it "does not set dry_type default when default is a proc" do
      expectation = described_class.new(:field, type: :string, default: -> { "test" })
      expect(expectation.dry_type.default?).to be false
    end
  end

  describe "#required?" do
    it "returns true for non-optional fields without default" do
      expectation = described_class.new(:name, type: :string)
      expect(expectation.required?).to be true
    end

    it "returns false for optional fields" do
      expectation = described_class.new(:name, type: :string, optional: true)
      expect(expectation.required?).to be false
    end

    it "returns false for fields with default value" do
      expectation = described_class.new(:name, type: :string, default: "test")
      expect(expectation.required?).to be false
    end

    it "returns false for fields with proc default" do
      expectation = described_class.new(:name, type: :string, default: -> { "test" })
      expect(expectation.required?).to be false
    end
  end

  describe "#has_default?" do
    it "returns true when dry_type has default" do
      expectation = described_class.new(:name, type: :string, default: "test")
      expect(expectation.has_default?).to be true
    end

    it "returns true when default is a proc" do
      expectation = described_class.new(:name, type: :string, default: -> { "test" })
      expect(expectation.has_default?).to be true
    end

    it "returns false when no default is set" do
      expectation = described_class.new(:name, type: :string)
      expect(expectation.has_default?).to be false
    end
  end

  describe "#has_fallback?" do
    it "returns true when fallback is set" do
      expectation = described_class.new(:name, type: :string, fallback: "default")
      expect(expectation.has_fallback?).to be true
    end

    it "returns false when fallback is nil" do
      expectation = described_class.new(:name, type: :string)
      expect(expectation.has_fallback?).to be false
    end

    it "returns true when fallback is a proc" do
      expectation = described_class.new(:name, type: :string, fallback: -> { "default" })
      expect(expectation.has_fallback?).to be true
    end
  end

  describe "type resolution" do
    it "resolves nil type to Any" do
      expectation = described_class.new(:field)
      expect(expectation.dry_type).to be_a(Dry::Types::Type)
    end

    it "resolves symbol types" do
      expectation = described_class.new(:field, type: :string)
      expect(expectation.dry_type).to be_a(Dry::Types::Type)
    end

    it "resolves class types" do
      expectation = described_class.new(:field, type: String)
      expect(expectation.dry_type).to be_a(Dry::Types::Type)
    end

    it "accepts Dry::Types directly" do
      dry_type = Expectant::Types::Strict::String
      expectation = described_class.new(:field, type: dry_type)
      expect(expectation.dry_type).to eq(dry_type)
    end
  end
end
