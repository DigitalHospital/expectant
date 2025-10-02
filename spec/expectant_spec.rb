# frozen_string_literal: true

RSpec.describe Expectant do
  it "has a version number" do
    expect(Expectant::VERSION).not_to be nil
  end

  describe "Dynamic Schema DSL" do
    let(:customer_invoice_class) do
      Class.new do
        def self.name
          "CustomerInvoice"
        end
      end
    end

    let(:customer_class) do
      Class.new do
        def self.exists?(id)
          id == 123
        end

        def self.name
          "Customer"
        end
      end
    end

    let(:test_class) do
      invoice_class = customer_invoice_class
      customer_class_ref = customer_class

      Class.new do
        include Expectant

        # Define schema types
        expectation :expects
        expectation :promises
        expectation :params

        # Define expects schema
        expects :customer_id, type: :integer
        expects :amount, type: :float
        expects :description, type: :string, optional: true
        expects :status, type: :string, default: "draft"
        expects :discount, type: :float, default: -> { 0.0 }
        expects :invoice, type: invoice_class, optional: true

        expects_rule(:amount) do
          key.failure("must be positive") if value && value <= 0
        end

        expects_rule(:customer_id) do
          key.failure("customer not found") unless customer_class_ref.exists?(value)
        end

        # Define promises schema
        promises :invoice, type: invoice_class
        promises :total, type: :float

        promises_rule(:total) do
          key.failure("must be positive") if value && value <= 0
        end

        # Define params schema
        params :limit, type: :integer, optional: true
        params :offset, type: :integer, optional: true, default: 0

        params_rule(:limit) do
          key.failure("must be between 1 and 100") if value && (value < 1 || value > 100)
        end
      end
    end

    describe "schema definitions" do
      it "stores schema definitions separately" do
        expect(test_class.schema_definitions.keys).to contain_exactly(:expects, :promises, :params)
      end

      it "stores expects fields correctly" do
        expects_def = test_class.schema_definitions[:expects]
        expect(expects_def[:fields].size).to eq(6)

        customer_id_field = expects_def[:fields].find { |f| f.name == :customer_id }
        expect(customer_id_field.type).to eq(:integer)
        expect(customer_id_field.required?).to be true

        description_field = expects_def[:fields].find { |f| f.name == :description }
        expect(description_field.optional).to be true

        status_field = expects_def[:fields].find { |f| f.name == :status }
        expect(status_field.default).to eq("draft")
      end

      it "stores promises fields correctly" do
        promises_def = test_class.schema_definitions[:promises]
        expect(promises_def[:fields].size).to eq(2)

        invoice_field = promises_def[:fields].find { |f| f.name == :invoice }
        expect(invoice_field.type).to eq(customer_invoice_class)
      end

      it "stores params fields correctly" do
        params_def = test_class.schema_definitions[:params]
        expect(params_def[:fields].size).to eq(2)

        limit_field = params_def[:fields].find { |f| f.name == :limit }
        expect(limit_field.type).to eq(:integer)
        expect(limit_field.optional).to be true
      end

      it "stores rules scoped to their schemas" do
        expects_def = test_class.schema_definitions[:expects]
        expect(expects_def[:rules].size).to eq(2)

        promises_def = test_class.schema_definitions[:promises]
        expect(promises_def[:rules].size).to eq(1)

        params_def = test_class.schema_definitions[:params]
        expect(params_def[:rules].size).to eq(1)
      end
    end

    describe "attribute accessors" do
      it "creates accessors for all schema fields" do
        instance = test_class.new
        expect(instance).to respond_to(:customer_id)
        expect(instance).to respond_to(:customer_id=)
        expect(instance).to respond_to(:amount)
        expect(instance).to respond_to(:total)
        expect(instance).to respond_to(:limit)
        expect(instance).to respond_to(:offset)
      end

      it "sets default values on initialization" do
        instance = test_class.new
        expect(instance.status).to eq("draft")
        expect(instance.discount).to eq(0.0)
        expect(instance.offset).to eq(0)
      end
    end

    describe "#get_schema" do
      it "builds and returns a dry-validation contract for expects" do
        schema = test_class.get_schema(:expects)
        expect(schema).to be_a(Dry::Validation::Contract)
      end

      it "builds and returns a dry-validation contract for promises" do
        schema = test_class.get_schema(:promises)
        expect(schema).to be_a(Dry::Validation::Contract)
      end

      it "builds and returns a dry-validation contract for params" do
        schema = test_class.get_schema(:params)
        expect(schema).to be_a(Dry::Validation::Contract)
      end

      it "caches schemas" do
        schema1 = test_class.get_schema(:expects)
        schema2 = test_class.get_schema(:expects)
        expect(schema1).to equal(schema2)
      end
    end

    describe "#validate" do
      context "expects schema" do
        it "validates valid input" do
          result = test_class.validate(:expects, {
            customer_id: 123,
            amount: 100.0,
            description: "Test invoice"
          })
          expect(result.success?).to be true
        end

        it "rejects invalid customer_id (custom rule)" do
          result = test_class.validate(:expects, {
            customer_id: 999,
            amount: 100.0
          })
          expect(result.success?).to be false
          expect(result.errors[:customer_id]).to include("customer not found")
        end

        it "rejects negative amount (custom rule)" do
          result = test_class.validate(:expects, {
            customer_id: 123,
            amount: -50.0
          })
          expect(result.success?).to be false
          expect(result.errors[:amount]).to include("must be positive")
        end

        it "rejects missing required fields" do
          result = test_class.validate(:expects, {
            amount: 100.0
          })
          expect(result.success?).to be false
          expect(result.errors[:customer_id]).to include("is missing")
        end

        it "rejects wrong types" do
          result = test_class.validate(:expects, {
            customer_id: "not_an_integer",
            amount: 100.0
          })
          expect(result.success?).to be false
          expect(result.errors[:customer_id]).to include("must be an integer")
        end
      end

      context "promises schema" do
        it "validates valid output" do
          result = test_class.validate(:promises, {
            invoice: customer_invoice_class.new,
            total: 100.0
          })
          expect(result.success?).to be true
        end

        it "rejects negative total (custom rule)" do
          result = test_class.validate(:promises, {
            invoice: customer_invoice_class.new,
            total: -50.0
          })
          expect(result.success?).to be false
          expect(result.errors[:total]).to include("must be positive")
        end

        it "rejects missing required fields" do
          result = test_class.validate(:promises, {
            total: 100.0
          })
          expect(result.success?).to be false
          expect(result.errors[:invoice]).to include("is missing")
        end
      end

      context "params schema" do
        it "validates valid params with optional fields" do
          result = test_class.validate(:params, {
            limit: 50
          })
          expect(result.success?).to be true
        end

        it "validates empty params (all optional)" do
          result = test_class.validate(:params, {})
          expect(result.success?).to be true
        end

        it "rejects limit out of range (custom rule)" do
          result = test_class.validate(:params, {
            limit: 200
          })
          expect(result.success?).to be false
          expect(result.errors[:limit]).to include("must be between 1 and 100")
        end
      end
    end

    describe "custom schema names" do
      let(:custom_class) do
        Class.new do
          include Expectant

          expectation :inputs
          expectation :outputs
          expectation :metadata

          inputs :data, type: :hash
          outputs :result, type: :string
          metadata :timestamp, type: :integer
        end
      end

      it "supports custom schema names" do
        expect(custom_class.schema_definitions.keys).to contain_exactly(:inputs, :outputs, :metadata)
      end

      it "creates methods for custom schemas" do
        expect(custom_class).to respond_to(:inputs)
        expect(custom_class).to respond_to(:outputs)
        expect(custom_class).to respond_to(:metadata)
        expect(custom_class).to respond_to(:inputs_rule)
        expect(custom_class).to respond_to(:outputs_rule)
        expect(custom_class).to respond_to(:metadata_rule)
      end

      it "validates custom schemas independently" do
        result = custom_class.validate(:inputs, { data: {} })
        expect(result.success?).to be true

        result = custom_class.validate(:outputs, { result: "success" })
        expect(result.success?).to be true

        result = custom_class.validate(:metadata, { timestamp: 123456 })
        expect(result.success?).to be true
      end
    end
  end
end
