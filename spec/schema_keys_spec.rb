# frozen_string_literal: true

RSpec.describe "Schema Keys" do
  let(:test_class) do
    Class.new do
      include Expectant

      expectation :expects
      expectation :promises
      expectation :params

      expects :customer_id, type: :integer
      expects :amount, type: :float
      expects :description, type: :string, optional: true

      promises :invoice, type: :string
      promises :total, type: :float

      params :limit, type: :integer, optional: true
      params :offset, type: :integer, optional: true
    end
  end

  describe ".schema_keys" do
    it "returns all field names for expects schema" do
      keys = test_class.schema_keys(:expects)
      expect(keys).to contain_exactly(:customer_id, :amount, :description)
    end

    it "returns all field names for promises schema" do
      keys = test_class.schema_keys(:promises)
      expect(keys).to contain_exactly(:invoice, :total)
    end

    it "returns all field names for params schema" do
      keys = test_class.schema_keys(:params)
      expect(keys).to contain_exactly(:limit, :offset)
    end

    it "returns empty array for non-existent schema" do
      keys = test_class.schema_keys(:nonexistent)
      expect(keys).to eq([])
    end

    it "works with string schema names" do
      keys = test_class.schema_keys("expects")
      expect(keys).to contain_exactly(:customer_id, :amount, :description)
    end

    it "includes both required and optional fields" do
      keys = test_class.schema_keys(:expects)
      expect(keys).to include(:customer_id) # required
      expect(keys).to include(:description) # optional
    end
  end
end
