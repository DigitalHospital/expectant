# frozen_string_literal: true

RSpec.describe Expectant::DSL do
  after do
    Expectant.reset_configuration!
  end

  describe ".included" do
    it "extends the class with ClassMethods" do
      test_class = Class.new do
        include Expectant::DSL
      end

      expect(test_class).to respond_to(:expects)
    end

    it "initializes @_expectant_schemas hash" do
      test_class = Class.new do
        include Expectant::DSL
      end

      expect(test_class.instance_variable_get(:@_expectant_schemas)).to eq({})
    end
  end

  describe ".expects" do
    let(:test_class) do
      Class.new do
        include Expectant::DSL

        expects :inputs
      end
    end

    it "creates a schema" do
      expect(test_class.instance_variable_get(:@_expectant_schemas)).to have_key(:inputs)
    end

    it "creates singular field definition method" do
      expect(test_class).to respond_to(:input)
    end

    it "creates validator method with default suffix" do
      expect(test_class).to respond_to(:input_rule)
    end

    it "creates reset method" do
      expect(test_class).to respond_to(:reset_inputs!)
    end

    it "creates class-level schema accessor" do
      expect(test_class).to respond_to(:inputs)
      expect(test_class.inputs).to be_a(Expectant::Schema)
    end

    it "creates instance-level schema accessor" do
      instance = test_class.new
      expect(instance).to respond_to(:inputs)
      expect(instance.inputs).to be_a(Expectant::BoundSchema)
    end

    it "raises error when schema already defined" do
      expect do
        Class.new do
          include Expectant::DSL

          expects :inputs
          expects :inputs
        end
      end.to raise_error(Expectant::SchemaError, /already defined/)
    end

    context "with custom singular name" do
      let(:custom_class) do
        Class.new do
          include Expectant::DSL

          expects :data, singular: :datum
        end
      end

      it "uses custom singular name for field method" do
        expect(custom_class).to respond_to(:datum)
      end

      it "uses custom name for validator method" do
        expect(custom_class).to respond_to(:datum_rule)
      end

      it "raises error with invalid singular option" do
        expect do
          Class.new do
            include Expectant::DSL

            expects :data, singular: 123
          end
        end.to raise_error(Expectant::ConfigurationError, /Invalid singular option/)
      end
    end

    context "with collision policy" do
      it "raises error on method collision with :error policy" do
        expect do
          Class.new do
            include Expectant::DSL

            def self.input
              "existing method"
            end

            expects :inputs, collision: :error
          end
        end.to raise_error(Expectant::ConfigurationError, /already defined/)
      end

      it "overwrites existing method with :force policy" do
        test_class = Class.new do
          include Expectant::DSL

          def self.input
            "original"
          end

          expects :inputs, collision: :force
        end

        expect(test_class).to respond_to(:input)
        # The new method should be the field definition method, not "original"
        test_class.input(:name, type: :string)
        expect(test_class.inputs.fields.size).to eq(1)
      end

      it "raises error on instance method collision with :error policy" do
        expect do
          Class.new do
            include Expectant::DSL

            def inputs
              "existing instance method"
            end

            expects :inputs, collision: :error
          end
        end.to raise_error(Expectant::ConfigurationError, /already defined/)
      end

      it "overwrites instance method with :force policy" do
        test_class = Class.new do
          include Expectant::DSL

          def inputs
            "original"
          end

          expects :inputs, collision: :force
        end

        instance = test_class.new
        expect(instance.inputs).to be_a(Expectant::BoundSchema)
      end
    end
  end

  describe "field definition" do
    let(:test_class) do
      Class.new do
        include Expectant::DSL

        expects :inputs
      end
    end

    it "adds fields to schema" do
      test_class.input :name, type: :string
      test_class.input :age, type: :integer

      expect(test_class.inputs.fields.size).to eq(2)
      expect(test_class.inputs.keys).to eq([:name, :age])
    end

    it "returns the expectation" do
      expectation = test_class.input :name, type: :string
      expect(expectation).to be_a(Expectant::Expectation)
      expect(expectation.name).to eq(:name)
    end
  end

  describe "validator definition" do
    let(:test_class) do
      Class.new do
        include Expectant::DSL

        expects :inputs
      end
    end

    it "adds single-field validator" do
      test_class.input :age, type: :integer
      test_class.input_rule(:age) do
        key.failure("must be positive") if value && value < 0
      end

      expect(test_class.inputs.validators.size).to eq(1)
      expect(test_class.inputs.validators.first[:name]).to eq(:age)
    end

    it "adds multi-field validator" do
      test_class.input :start_date, type: :date
      test_class.input :end_date, type: :date
      test_class.input_rule(:start_date, :end_date) do
        base.failure("end must be after start")
      end

      expect(test_class.inputs.validators.size).to eq(1)
      expect(test_class.inputs.validators.first[:name]).to eq([:start_date, :end_date])
    end

    it "adds global validator without field name" do
      test_class.input :name, type: :string
      test_class.input_rule do
        base.failure("global error")
      end

      expect(test_class.inputs.validators.size).to eq(1)
      expect(test_class.inputs.validators.first[:name]).to be_nil
    end

    context "with custom validator method name" do
      before do
        Expectant.configure do |config|
          config.validator_prefix = "validate"
          config.validator_suffix = nil
        end
      end

      it "uses configured validator method name" do
        custom_class = Class.new do
          include Expectant::DSL

          expects :inputs
        end

        expect(custom_class).to respond_to(:validate_input)
        expect(custom_class).not_to respond_to(:input_rule)
      end
    end
  end

  describe "#reset_inherited_expectations!" do
    it "clears all schemas" do
      test_class = Class.new do
        include Expectant::DSL

        expects :inputs
        input :name, type: :string
      end

      test_class.reset_inherited_expectations!

      expect(test_class.instance_variable_get(:@_expectant_schemas)).to eq({})
    end
  end

  describe "schema reset" do
    let(:test_class) do
      Class.new do
        include Expectant::DSL

        expects :inputs
      end
    end

    it "clears schema fields and validators" do
      test_class.input :name, type: :string
      test_class.input_rule(:name) { key.failure("error") }

      test_class.reset_inputs!

      expect(test_class.inputs.fields).to eq([])
      expect(test_class.inputs.validators).to eq([])
    end
  end

  describe "inheritance" do
    let(:parent_class) do
      Class.new do
        include Expectant::DSL

        expects :inputs

        input :name, type: :string
        input :age, type: :integer
        input_rule(:age) { key.failure("must be positive") if value && value < 0 }
      end
    end

    let(:child_class) { Class.new(parent_class) }

    it "inherits parent schemas" do
      expect(child_class.inputs).to be_a(Expectant::Schema)
      expect(child_class.inputs.fields.size).to eq(2)
      expect(child_class.inputs.validators.size).to eq(1)
    end

    it "allows child to add more fields" do
      child_class.input :email, type: :string

      expect(child_class.inputs.fields.size).to eq(3)
      expect(parent_class.inputs.fields.size).to eq(2)
    end

    it "allows child to add more validators" do
      child_class.input_rule(:name) { key.failure("required") if value.nil? }

      expect(child_class.inputs.validators.size).to eq(2)
      expect(parent_class.inputs.validators.size).to eq(1)
    end

    it "does not affect parent when child is modified" do
      original_parent_fields = parent_class.inputs.fields.size
      child_class.input :new_field, type: :string

      expect(parent_class.inputs.fields.size).to eq(original_parent_fields)
    end

    it "handles multiple levels of inheritance" do
      grandchild_class = Class.new(child_class)
      grandchild_class.input :phone, type: :string

      expect(grandchild_class.inputs.fields.size).to eq(3)
      expect(child_class.inputs.fields.size).to eq(2)
      expect(parent_class.inputs.fields.size).to eq(2)
    end

    it "handles inheritance when parent has no schemas" do
      empty_parent = Class.new do
        include Expectant::DSL
      end

      empty_child = Class.new(empty_parent) do
        include Expectant::DSL  # Re-include to initialize schemas
      end

      empty_child.expects :inputs
      empty_child.input :name, type: :string

      expect(empty_child.inputs.fields.size).to eq(1)
    end

    it "handles inheritance when parent has empty schemas hash" do
      parent = Class.new do
        include Expectant::DSL
      end

      # Manually set empty schemas to simulate edge case
      parent.instance_variable_set(:@_expectant_schemas, {})

      child = Class.new(parent) do
        include Expectant::DSL  # Re-include to initialize schemas
      end

      child.expects :inputs
      child.input :name, type: :string

      expect(child.inputs.fields.size).to eq(1)
    end
  end

  describe "multiple schemas" do
    let(:test_class) do
      Class.new do
        include Expectant::DSL

        expects :inputs
        expects :outputs
        expects :metadata
      end
    end

    it "creates separate schemas" do
      schemas = test_class.instance_variable_get(:@_expectant_schemas)
      expect(schemas.keys).to contain_exactly(:inputs, :outputs, :metadata)
    end

    it "creates separate field methods" do
      expect(test_class).to respond_to(:input)
      expect(test_class).to respond_to(:output)
      expect(test_class).to respond_to(:metadatum)
    end

    it "creates separate validator methods" do
      expect(test_class).to respond_to(:input_rule)
      expect(test_class).to respond_to(:output_rule)
      expect(test_class).to respond_to(:metadatum_rule)
    end

    it "maintains independent fields" do
      test_class.input :name, type: :string
      test_class.output :result, type: :string
      test_class.metadatum :timestamp, type: :integer

      expect(test_class.inputs.fields.size).to eq(1)
      expect(test_class.outputs.fields.size).to eq(1)
      expect(test_class.metadata.fields.size).to eq(1)
    end
  end
end
