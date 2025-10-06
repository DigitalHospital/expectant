# frozen_string_literal: true

RSpec.describe "Rule Context" do
  describe "accessing external data in rules via context" do
    let(:test_class) do
      Class.new do
        include Expectant

        def self._per_page_max
          100
        end

        def self.columns
          [
            OpenStruct.new(name: "id", supports_order?: true),
            OpenStruct.new(name: "created_at", supports_order?: true),
            OpenStruct.new(name: "status", supports_order?: false)
          ]
        end

        expectation :pagination_params

        pagination_params :page, type: :integer, default: 1
        pagination_params :per_page, type: :integer, default: 25
        pagination_params :order, type: :string, optional: true
        pagination_params :descending, type: :boolean, default: false

        # Use context to access external values (accessed via self.context)
        pagination_params_rule(:per_page) do
          max = context[:per_page_max]
          if value && max && value > max
            key.failure("must be ≤ #{max}")
          end
        end

        pagination_params_rule(:order) do
          valid_columns = context[:orderable_columns] || []
          if value && !valid_columns.include?(value.to_s)
            key.failure("must be a valid orderable column")
          end
        end
      end
    end

    it "can access context values in rules" do
      instance = test_class.new
      result = instance.validate(
        :pagination_params,
        {per_page: 150},
        context: {per_page_max: 100}
      )

      expect(result.success?).to be false
      expect(result.errors[:per_page]).to include("must be ≤ 100")
    end

    it "validates order field using context" do
      instance = test_class.new
      result = instance.validate(
        :pagination_params,
        {order: "invalid_column"},
        context: {orderable_columns: ["id", "created_at"]}
      )

      expect(result.success?).to be false
      expect(result.errors[:order]).to include("must be a valid orderable column")
    end

    it "passes validation when order is valid" do
      instance = test_class.new
      result = instance.validate(
        :pagination_params,
        {order: "id"},
        context: {orderable_columns: ["id", "created_at"]}
      )

      expect(result.success?).to be true
    end

    it "can combine multiple context values" do
      instance = test_class.new
      result = instance.validate(
        :pagination_params,
        {per_page: 50, order: "created_at"},
        context: {
          per_page_max: 100,
          orderable_columns: ["id", "created_at"]
        }
      )

      expect(result.success?).to be true
    end
  end

  describe "context usage pattern" do
    it "shows how to use class methods via context" do
      my_class = Class.new do
        include Expectant

        def self._per_page_max
          100
        end

        def self.orderable_columns
          ["id", "name", "created_at"]
        end

        expectation :params

        params :per_page, type: :integer
        params :order, type: :string, optional: true

        params_rule(:per_page) do
          max = context[:per_page_max]
          key.failure("must be ≤ #{max}") if value > max
        end

        params_rule(:order) do
          columns = context[:columns] || []
          key.failure("invalid column") if value && !columns.include?(value)
        end

        # Helper method to validate with class context
        def self.validate_with_context(data)
          new.validate(:params, data, context: {
            per_page_max: _per_page_max,
            columns: orderable_columns
          })
        end
      end

      # Use the helper method
      result = my_class.validate_with_context({per_page: 50, order: "name"})
      expect(result.success?).to be true

      result = my_class.validate_with_context({per_page: 150, order: "name"})
      expect(result.success?).to be false
      expect(result.errors[:per_page]).to include("must be ≤ 100")
    end
  end
end
