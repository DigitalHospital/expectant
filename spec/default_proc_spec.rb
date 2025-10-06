# frozen_string_literal: true

RSpec.describe "Default Proc Values" do
  describe "proc default values" do
    it "works with simple lambda returning static value" do
      test_class = Class.new do
        include Expectant

        expectation :state
        state :per_page, type: :integer, default: -> { 25 }
      end

      instance = test_class.new
      result = instance.validate(:state, {})

      expect(result.success?).to be true
      expect(result.to_h[:per_page]).to eq(25)
    end

    it "works with lambda accessing class attributes" do
      test_class = Class.new do
        include Expectant

        @per_page_default = 25

        class << self
          attr_accessor :per_page_default
        end

        expectation :state
        state :per_page, type: :integer, default: -> { self.class.per_page_default }
      end

      instance = test_class.new
      result = instance.validate(:state, {})

      expect(result.success?).to be true
      expect(result.to_h[:per_page]).to eq(25)
    end

    it "respects provided values over defaults" do
      test_class = Class.new do
        include Expectant

        expectation :state
        state :per_page, type: :integer, default: -> { 25 }
      end

      instance = test_class.new
      result = instance.validate(:state, {per_page: 50})

      expect(result.success?).to be true
      expect(result.to_h[:per_page]).to eq(50)
    end

    it "works with proc defaults and fallbacks together" do
      test_class = Class.new do
        include Expectant

        @per_page_default = 25

        class << self
          attr_accessor :per_page_default
        end

        expectation :state
        state :per_page, type: :integer,
          default: -> { self.class.per_page_default },
          fallback: -> { self.class.per_page_default }

        state_rule(:per_page) do
          if value && value > 100
            key.failure("must be ≤ 100")
          end
        end
      end

      instance = test_class.new

      # Test default when no value provided
      result = instance.validate(:state, {})
      expect(result.success?).to be true
      expect(result.to_h[:per_page]).to eq(25)

      # Test fallback when validation fails
      result = instance.validate(:state, {per_page: 200})
      expect(result.success?).to be true
      expect(result.to_h[:per_page]).to eq(25)
    end
  end
end
