# frozen_string_literal: true

RSpec.describe Expectant::BoundSchema do
  let(:test_class) do
    Class.new do
      attr_accessor :default_name, :fallback_value

      def initialize
        @default_name = "Default Name"
        @fallback_value = "Fallback Value"
      end
    end
  end

  let(:instance) { test_class.new }
  let(:schema) { Expectant::Schema.new(:test) }
  subject(:bound_schema) { described_class.new(instance, schema) }

  describe "#initialize" do
    it "stores the instance and schema" do
      expect(bound_schema.instance_variable_get(:@instance)).to eq(instance)
      expect(bound_schema.instance_variable_get(:@schema)).to eq(schema)
    end
  end

  describe "#keys" do
    it "delegates to schema.keys" do
      field1 = Expectant::Expectation.new(:name, type: :string)
      field2 = Expectant::Expectation.new(:age, type: :integer)

      schema.add_field(field1)
      schema.add_field(field2)

      expect(bound_schema.keys).to eq([:name, :age])
    end
  end

  describe "#contract" do
    it "delegates to schema.contract" do
      expect(bound_schema.contract).to eq(schema.contract)
    end
  end

  describe "#validate" do
    context "with basic validation" do
      before do
        field = Expectant::Expectation.new(:name, type: :string)
        schema.add_field(field)
      end

      it "validates valid data" do
        result = bound_schema.validate({name: "John"})
        expect(result.success?).to be true
      end

      it "returns errors for invalid data" do
        result = bound_schema.validate({})
        expect(result.success?).to be false
        expect(result.errors[:name]).to include("is missing")
      end
    end

    context "with proc defaults" do
      before do
        field = Expectant::Expectation.new(
          :name,
          type: :string,
          default: -> { default_name }
        )
        schema.add_field(field)
      end

      it "applies proc defaults for missing fields" do
        result = bound_schema.validate({})
        expect(result.success?).to be true
        expect(result.to_h[:name]).to eq("Default Name")
      end

      it "does not override provided values" do
        result = bound_schema.validate({name: "Custom Name"})
        expect(result.success?).to be true
        expect(result.to_h[:name]).to eq("Custom Name")
      end

      it "evaluates proc in instance context" do
        instance.default_name = "Instance Default"
        result = bound_schema.validate({})
        expect(result.to_h[:name]).to eq("Instance Default")
      end
    end

    context "with static defaults" do
      before do
        field = Expectant::Expectation.new(:status, type: :string, default: "pending")
        schema.add_field(field)
      end

      it "applies static defaults through dry-types" do
        result = bound_schema.validate({})
        expect(result.success?).to be true
        expect(result.to_h[:status]).to eq("pending")
      end
    end

    context "with fallbacks" do
      before do
        field = Expectant::Expectation.new(
          :name,
          type: :string,
          fallback: -> { fallback_value }
        )
        schema.add_field(field)

        validator = {
          name: :name,
          block: proc { key.failure("invalid name") if value == "invalid" }
        }
        schema.add_validator(validator)
      end

      it "applies fallback when validation fails" do
        result = bound_schema.validate({name: "invalid"})
        expect(result.success?).to be true
        expect(result.to_h[:name]).to eq("Fallback Value")
      end

      it "does not apply fallback when validation succeeds" do
        result = bound_schema.validate({name: "valid"})
        expect(result.success?).to be true
        expect(result.to_h[:name]).to eq("valid")
      end

      it "evaluates proc fallback in instance context" do
        instance.fallback_value = "Instance Fallback"
        result = bound_schema.validate({name: "invalid"})
        expect(result.to_h[:name]).to eq("Instance Fallback")
      end
    end

    context "with static fallbacks" do
      before do
        field = Expectant::Expectation.new(
          :count,
          type: :integer,
          fallback: 0
        )
        schema.add_field(field)

        validator = {
          name: :count,
          block: proc { key.failure("must be positive") if value && value < 0 }
        }
        schema.add_validator(validator)
      end

      it "applies static fallback when validation fails" do
        result = bound_schema.validate({count: -5})
        expect(result.success?).to be true
        expect(result.to_h[:count]).to eq(0)
      end
    end

    context "with context" do
      before do
        field = Expectant::Expectation.new(:name, type: :string)
        schema.add_field(field)

        validator = {
          name: :name,
          block: proc { key.failure("restricted") if context[:restricted] && value == "admin" }
        }
        schema.add_validator(validator)
      end

      it "passes context to contract" do
        result = bound_schema.validate({name: "admin"}, context: {restricted: true})
        expect(result.success?).to be false
        expect(result.errors[:name]).to include("restricted")
      end

      it "allows validation to succeed without restricted context" do
        result = bound_schema.validate({name: "admin"}, context: {restricted: false})
        expect(result.success?).to be true
      end
    end

    context "with multiple fields having fallbacks" do
      before do
        field1 = Expectant::Expectation.new(:name, type: :string, fallback: "Unknown")
        field2 = Expectant::Expectation.new(:age, type: :integer, fallback: 0)

        schema.add_field(field1)
        schema.add_field(field2)

        validator1 = {
          name: :name,
          block: proc { key.failure("invalid") if value == "bad" }
        }
        validator2 = {
          name: :age,
          block: proc { key.failure("invalid") if value && value < 0 }
        }

        schema.add_validator(validator1)
        schema.add_validator(validator2)
      end

      it "applies multiple fallbacks independently" do
        result = bound_schema.validate({name: "bad", age: -5})
        expect(result.success?).to be true
        expect(result.to_h[:name]).to eq("Unknown")
        expect(result.to_h[:age]).to eq(0)
      end

      it "only applies fallback to failing fields" do
        result = bound_schema.validate({name: "good", age: -5})
        expect(result.success?).to be true
        expect(result.to_h[:name]).to eq("good")
        expect(result.to_h[:age]).to eq(0)
      end
    end
  end
end
