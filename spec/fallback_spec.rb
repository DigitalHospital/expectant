# frozen_string_literal: true

RSpec.describe "Fallback Values" do
  describe "static fallback values" do
    let(:test_class) do
      Class.new do
        include Expectant

        expectation :expects
        expects :per_page, type: :integer, fallback: 25

        expects_rule(:per_page) do
          if value && (value < 1 || value > 100)
            key.failure("must be between 1 and 100")
          end
        end
      end
    end

    it "uses fallback when validation fails" do
      instance = test_class.new
      result = instance.validate(:expects, {per_page: 200})

      expect(result.success?).to be true
      expect(result.to_h[:per_page]).to eq(25)
    end

    it "uses provided value when valid" do
      instance = test_class.new
      result = instance.validate(:expects, {per_page: 50})

      expect(result.success?).to be true
      expect(result.to_h[:per_page]).to eq(50)
    end
  end

  describe "proc fallback values" do
    let(:test_class) do
      Class.new do
        include Expectant

        @per_page_default = 25

        class << self
          attr_accessor :per_page_default
        end

        expectation :state
        state :per_page, type: :integer, fallback: -> { self.class.per_page_default }

        state_rule(:per_page) do
          if value && value > 100
            key.failure("must be ≤ 100")
          end
        end
      end
    end

    it "evaluates proc fallback in instance context" do
      instance = test_class.new
      result = instance.validate(:state, {per_page: 200})

      expect(result.success?).to be true
      expect(result.to_h[:per_page]).to eq(25)
    end

    it "uses class attribute from fallback proc" do
      test_class.per_page_default = 50
      instance = test_class.new
      result = instance.validate(:state, {per_page: 200})

      expect(result.success?).to be true
      expect(result.to_h[:per_page]).to eq(50)
    end
  end

  describe "fallback with default" do
    let(:test_class) do
      Class.new do
        include Expectant

        expectation :expects
        expects :per_page, type: :integer, default: 10, fallback: 25

        expects_rule(:per_page) do
          if value && value > 100
            key.failure("must be ≤ 100")
          end
        end
      end
    end

    it "uses default when value not provided" do
      instance = test_class.new
      result = instance.validate(:expects, {})

      expect(result.success?).to be true
      expect(result.to_h[:per_page]).to eq(10)
    end

    it "uses fallback when default fails validation" do
      # This is an edge case - if someone provides a bad default
      test_class2 = Class.new do
        include Expectant

        expectation :expects
        expects :per_page, type: :integer, default: 200, fallback: 25

        expects_rule(:per_page) do
          if value && value > 100
            key.failure("must be ≤ 100")
          end
        end
      end

      instance = test_class2.new
      result = instance.validate(:expects, {})

      expect(result.success?).to be true
      expect(result.to_h[:per_page]).to eq(25)
    end
  end

  describe "multiple fallbacks" do
    let(:test_class) do
      Class.new do
        include Expectant

        expectation :pagination
        pagination :page, type: :integer, default: 1, fallback: 1
        pagination :per_page, type: :integer, default: 25, fallback: 25
        pagination :order, type: :string, optional: true, fallback: "id"

        pagination_rule(:page) do
          key.failure("must be positive") if value && value < 1
        end

        pagination_rule(:per_page) do
          key.failure("must be between 1-100") if value && (value < 1 || value > 100)
        end

        pagination_rule(:order) do
          valid_columns = ["id", "created_at"]
          if value && !valid_columns.include?(value)
            key.failure("invalid column")
          end
        end
      end
    end

    it "applies multiple fallbacks when multiple fields fail" do
      instance = test_class.new
      result = instance.validate(:pagination, {
        page: -1,
        per_page: 500,
        order: "invalid"
      })

      expect(result.success?).to be true
      expect(result.to_h[:page]).to eq(1)
      expect(result.to_h[:per_page]).to eq(25)
      expect(result.to_h[:order]).to eq("id")
    end
  end

  describe "fallback with false value" do
    let(:test_class) do
      Class.new do
        include Expectant

        expectation :expects
        expects :flag, type: :boolean, fallback: false

        expects_rule(:flag) do
          # Simulate some validation that could fail
          key.failure("invalid") if value.nil?
        end
      end
    end

    it "correctly applies false as fallback" do
      instance = test_class.new
      result = instance.validate(:expects, {flag: nil})

      expect(result.success?).to be true
      expect(result.to_h[:flag]).to eq(false)
    end
  end
end
