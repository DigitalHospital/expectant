# frozen_string_literal: true

RSpec.describe "Dry-Types Integration" do
  describe "symbol shortcuts" do
    let(:test_class) do
      Class.new do
        include Expectant

        expectation :expects
        expects :name, type: :string
        expects :age, type: :integer
        expects :birth_date, type: :date
        expects :created_at, type: :datetime
      end
    end

    it "resolves symbol types to dry-types" do
      instance = test_class.new
      result = instance.validate(:expects, {
        name: "John",
        age: 30,
        birth_date: Date.new(1994, 1, 1),
        created_at: DateTime.now
      })

      expect(result.success?).to be true
    end

    it "validates type correctness" do
      instance = test_class.new
      result = instance.validate(:expects, {
        name: "John",
        age: "not an integer",
        birth_date: Date.new(1994, 1, 1),
        created_at: DateTime.now
      })

      expect(result.success?).to be false
      expect(result.errors[:age]).to_not be_empty
    end
  end

  describe "array types" do
    let(:test_class) do
      Class.new do
        include Expectant

        expectation :expects
        expects :tags, type: [:array, :string]
        expects :numbers, type: [:array, :integer]
      end
    end

    it "validates arrays of specific types" do
      instance = test_class.new
      result = instance.validate(:expects, {
        tags: ["ruby", "rails", "dry-rb"],
        numbers: [1, 2, 3]
      })

      expect(result.success?).to be true
    end

    it "rejects invalid array item types" do
      instance = test_class.new
      result = instance.validate(:expects, {
        tags: ["ruby", "rails", 123],  # 123 is not a string
        numbers: [1, 2, 3]
      })

      expect(result.success?).to be false
    end
  end

  describe "direct dry-types usage" do
    let(:customer_class) do
      Class.new do
        def self.name
          "Customer"
        end
      end
    end

    let(:test_class) do
      customer = customer_class
      Class.new do
        include Expectant

        expectation :expects

        # Direct dry-types with defaults
        expects :status, type: Expectant::Types::String.default("draft")
        expects :discount, type: Expectant::Types::Float.default(0.0)

        # Coercible types for params
        expects :page, type: Expectant::Types::Params::Integer.optional

        # Arrays of custom objects
        expects :customers, type: Expectant::Types::Array.of(Expectant::Types.Instance(customer))
      end
    end

    it "uses dry-types defaults" do
      instance = test_class.new
      result = instance.validate(:expects, {
        customers: [customer_class.new]
      })

      expect(result.success?).to be true
      expect(result.to_h[:status]).to eq("draft")
      expect(result.to_h[:discount]).to eq(0.0)
    end

    it "coerces param types" do
      instance = test_class.new
      result = instance.validate(:expects, {
        page: "42",  # String will be coerced to integer
        customers: [customer_class.new]
      })

      expect(result.success?).to be true
      expect(result.to_h[:page]).to eq(42)
    end
  end

  describe "dry-types defaults and optional" do
    let(:test_class) do
      Class.new do
        include Expectant

        expectation :expects
        # Use dry-types .default() for defaults
        expects :status, type: Expectant::Types::String.default("draft")
        expects :transfer_date, type: Expectant::Types::Date.default { Date.today }
        # Use .optional for optional fields
        expects :description, type: Expectant::Types::String.optional
      end
    end

    it "applies dry-types defaults" do
      instance = test_class.new
      result = instance.validate(:expects, {})

      expect(result.success?).to be true
      expect(result.to_h[:status]).to eq("draft")
      expect(result.to_h[:transfer_date]).to eq(Date.today)
    end

    it "handles optional fields" do
      instance = test_class.new
      result = instance.validate(:expects, {})

      expect(result.success?).to be true
      expect(result.to_h[:description]).to be_nil
    end
  end
end
