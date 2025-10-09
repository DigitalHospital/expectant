# frozen_string_literal: true

RSpec.describe Expectant::Schema do
  subject(:schema) { described_class.new(:test_schema) }

  describe "#initialize" do
    it "creates a schema with a name" do
      expect(schema.name).to eq(:test_schema)
    end

    it "initializes empty fields array" do
      expect(schema.fields).to eq([])
    end

    it "initializes empty validators array" do
      expect(schema.validators).to eq([])
    end
  end

  describe "#keys" do
    it "returns empty array when no fields added" do
      expect(schema.keys).to eq([])
    end

    it "returns field names" do
      field1 = Expectant::Expectation.new(:name, type: :string)
      field2 = Expectant::Expectation.new(:age, type: :integer)

      schema.add_field(field1)
      schema.add_field(field2)

      expect(schema.keys).to eq([:name, :age])
    end
  end

  describe "#add_field" do
    it "adds an expectation to fields" do
      expectation = Expectant::Expectation.new(:name, type: :string)
      schema.add_field(expectation)

      expect(schema.fields).to include(expectation)
      expect(schema.fields.size).to eq(1)
    end

    it "clears cached contract when field is added" do
      schema.contract # Build contract
      expect(schema.instance_variable_get(:@contract_class)).not_to be_nil

      expectation = Expectant::Expectation.new(:name, type: :string)
      schema.add_field(expectation)

      expect(schema.instance_variable_get(:@contract_class)).to be_nil
    end

    it "allows adding multiple fields" do
      field1 = Expectant::Expectation.new(:name, type: :string)
      field2 = Expectant::Expectation.new(:age, type: :integer)

      schema.add_field(field1)
      schema.add_field(field2)

      expect(schema.fields.size).to eq(2)
    end
  end

  describe "#add_validator" do
    it "adds a validator definition" do
      validator = { name: :name, block: proc { true } }
      schema.add_validator(validator)

      expect(schema.validators).to include(validator)
      expect(schema.validators.size).to eq(1)
    end

    it "clears cached contract when validator is added" do
      schema.contract # Build contract
      expect(schema.instance_variable_get(:@contract_class)).not_to be_nil

      validator = { name: :name, block: proc { true } }
      schema.add_validator(validator)

      expect(schema.instance_variable_get(:@contract_class)).to be_nil
    end

    it "allows adding multiple validators" do
      validator1 = { name: :name, block: proc { true } }
      validator2 = { name: :age, block: proc { true } }

      schema.add_validator(validator1)
      schema.add_validator(validator2)

      expect(schema.validators.size).to eq(2)
    end
  end

  describe "#contract" do
    it "returns a Dry::Validation::Contract class" do
      expect(schema.contract).to be < Dry::Validation::Contract
    end

    it "caches the contract class" do
      contract1 = schema.contract
      contract2 = schema.contract

      expect(contract1).to equal(contract2)
    end

    it "builds contract with fields as required/optional" do
      required_field = Expectant::Expectation.new(:name, type: :string)
      optional_field = Expectant::Expectation.new(:age, type: :integer, optional: true)

      schema.add_field(required_field)
      schema.add_field(optional_field)

      contract = schema.contract.new
      result = contract.call({ name: "John" })

      expect(result.success?).to be true
    end

    it "includes custom validators in contract" do
      field = Expectant::Expectation.new(:age, type: :integer)
      schema.add_field(field)

      validator = {
        name: :age,
        block: proc { key.failure("must be positive") if value && value < 0 }
      }
      schema.add_validator(validator)

      contract = schema.contract.new
      result = contract.call({ age: -5 })

      expect(result.success?).to be false
      expect(result.errors[:age]).to include("must be positive")
    end

    it "supports global validators without field name" do
      field = Expectant::Expectation.new(:name, type: :string)
      schema.add_field(field)

      validator = {
        name: nil,
        block: proc { base.failure("global error") if values[:name] == "invalid" }
      }
      schema.add_validator(validator)

      contract = schema.contract.new
      result = contract.call({ name: "invalid" })

      expect(result.success?).to be false
    end

    it "supports validators for multiple keys" do
      field1 = Expectant::Expectation.new(:start_date, type: :date)
      field2 = Expectant::Expectation.new(:end_date, type: :date)
      schema.add_field(field1)
      schema.add_field(field2)

      validator = {
        name: [:start_date, :end_date],
        block: proc { base.failure("end_date must be after start_date") }
      }
      schema.add_validator(validator)

      contract = schema.contract.new
      expect(contract).to be_a(Dry::Validation::Contract)
    end
  end

  describe "#duplicate" do
    it "creates a copy of the schema" do
      field = Expectant::Expectation.new(:name, type: :string)
      validator = { name: :name, block: proc { true } }

      schema.add_field(field)
      schema.add_validator(validator)

      dup = schema.duplicate

      expect(dup.name).to eq(schema.name)
      expect(dup.fields).to eq(schema.fields)
      expect(dup.validators).to eq(schema.validators)
    end

    it "creates independent copies of fields and validators" do
      field = Expectant::Expectation.new(:name, type: :string)
      schema.add_field(field)

      dup = schema.duplicate
      new_field = Expectant::Expectation.new(:age, type: :integer)
      dup.add_field(new_field)

      expect(schema.fields.size).to eq(1)
      expect(dup.fields.size).to eq(2)
    end
  end

  describe "#freeze" do
    it "freezes fields and validators" do
      field = Expectant::Expectation.new(:name, type: :string)
      schema.add_field(field)
      schema.freeze

      expect(schema.fields).to be_frozen
      expect(schema.validators).to be_frozen
    end

    it "prevents adding new fields after freeze" do
      schema.freeze
      expect { schema.add_field(Expectant::Expectation.new(:name, type: :string)) }.to raise_error(FrozenError)
    end
  end

  describe "#reset!" do
    it "clears all fields and validators" do
      field = Expectant::Expectation.new(:name, type: :string)
      validator = { name: :name, block: proc { true } }

      schema.add_field(field)
      schema.add_validator(validator)
      schema.reset!

      expect(schema.fields).to eq([])
      expect(schema.validators).to eq([])
    end

    it "clears cached contract" do
      schema.contract # Build contract
      schema.reset!

      expect(schema.instance_variable_get(:@contract_class)).to be_nil
    end
  end
end
