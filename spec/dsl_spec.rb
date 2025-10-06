# frozen_string_literal: true

RSpec.describe Expectant::DSL do
  describe ".expectation" do
    it "dynamically defines field definition method" do
      test_class = Class.new do
        include Expectant

        expectation :inputs
      end

      expect(test_class).to respond_to(:inputs)
    end

    it "dynamically defines rule method" do
      test_class = Class.new do
        include Expectant

        expectation :inputs
      end

      expect(test_class).to respond_to(:inputs_rule)
    end

    it "supports multiple schema definitions" do
      test_class = Class.new do
        include Expectant

        expectation :expects
        expectation :promises
        expectation :params
      end

      expect(test_class).to respond_to(:expects)
      expect(test_class).to respond_to(:expects_rule)
      expect(test_class).to respond_to(:promises)
      expect(test_class).to respond_to(:promises_rule)
      expect(test_class).to respond_to(:params)
      expect(test_class).to respond_to(:params_rule)
    end

    it "supports custom schema names" do
      test_class = Class.new do
        include Expectant

        expectation :my_custom_schema
      end

      expect(test_class).to respond_to(:my_custom_schema)
      expect(test_class).to respond_to(:my_custom_schema_rule)
    end

    it "creates schema definitions storage" do
      test_class = Class.new do
        include Expectant

        expectation :inputs
      end

      expect(test_class.schema_definitions).to have_key(:inputs)
      expect(test_class.schema_definitions[:inputs]).to have_key(:fields)
      expect(test_class.schema_definitions[:inputs]).to have_key(:rules)
    end
  end

  describe "dynamically defined field methods" do
    let(:test_class) do
      Class.new do
        include Expectant

        expectation :expects
      end
    end

    it "adds fields to schema definition" do
      test_class.expects :name, type: :string
      test_class.expects :age, type: :integer

      expect(test_class.schema_definitions[:expects][:fields].size).to eq(2)
      expect(test_class.schema_definitions[:expects][:fields][0].name).to eq(:name)
      expect(test_class.schema_definitions[:expects][:fields][1].name).to eq(:age)
    end

    it "returns an Expectation object" do
      result = test_class.expects :email, type: :string

      expect(result).to be_a(Expectant::Expectation)
      expect(result.name).to eq(:email)
      expect(result.type).to eq(:string)
    end
  end

  describe "dynamically defined rule methods" do
    let(:test_class) do
      Class.new do
        include Expectant

        expectation :expects
      end
    end

    it "adds rules with single field name" do
      test_class.expects_rule(:name) do
        key.failure("is invalid")
      end

      expect(test_class.schema_definitions[:expects][:rules].size).to eq(1)
      expect(test_class.schema_definitions[:expects][:rules][0][:name]).to eq(:name)
      expect(test_class.schema_definitions[:expects][:rules][0][:block]).to be_a(Proc)
    end

    it "adds rules with multiple field names" do
      test_class.expects_rule(:kilometers, :miles) do
        if key?(:kilometers) && key?(:miles)
          base.failure("must only contain one of: kilometers, miles")
        end
      end

      expect(test_class.schema_definitions[:expects][:rules].size).to eq(1)
      expect(test_class.schema_definitions[:expects][:rules][0][:name]).to eq([:kilometers, :miles])
      expect(test_class.schema_definitions[:expects][:rules][0][:block]).to be_a(Proc)
    end

    it "adds global rules without field names" do
      test_class.expects_rule do
        # global validation
      end

      expect(test_class.schema_definitions[:expects][:rules].size).to eq(1)
      expect(test_class.schema_definitions[:expects][:rules][0][:name]).to be_nil
      expect(test_class.schema_definitions[:expects][:rules][0][:block]).to be_a(Proc)
    end

    it "allows multiple rules for different schemas" do
      test_class = Class.new do
        include Expectant

        expectation :expects
        expectation :promises
      end

      test_class.expects_rule(:name) { key.failure("invalid") }
      test_class.promises_rule(:result) { key.failure("invalid") }

      expect(test_class.schema_definitions[:expects][:rules].size).to eq(1)
      expect(test_class.schema_definitions[:promises][:rules].size).to eq(1)
    end
  end

  describe "schema isolation" do
    it "keeps fields and rules separate between schemas" do
      test_class = Class.new do
        include Expectant

        expectation :expects
        expectation :promises

        expects :input, type: :string
        expects_rule(:input) { key.failure("invalid") }

        promises :output, type: :string
        promises_rule(:output) { key.failure("invalid") }
      end

      expect(test_class.schema_definitions[:expects][:fields].size).to eq(1)
      expect(test_class.schema_definitions[:expects][:rules].size).to eq(1)
      expect(test_class.schema_definitions[:promises][:fields].size).to eq(1)
      expect(test_class.schema_definitions[:promises][:rules].size).to eq(1)

      expect(test_class.schema_definitions[:expects][:fields][0].name).to eq(:input)
      expect(test_class.schema_definitions[:promises][:fields][0].name).to eq(:output)
    end
  end
end
