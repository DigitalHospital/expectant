# frozen_string_literal: true

RSpec.describe Expectant::Types do
  describe ".resolve" do
    context "with nil type" do
      it "returns Any type" do
        type = described_class.resolve(nil)
        expect(type).to be_a(Dry::Types::Type)
        expect(type).to eq(described_class::Any)
      end
    end

    context "with symbol types" do
      it "resolves :string to Params::String" do
        type = described_class.resolve(:string)
        expect(type).to eq(described_class::Params::String)
      end

      it "resolves :str to Params::String" do
        type = described_class.resolve(:str)
        expect(type).to eq(described_class::Params::String)
      end

      it "resolves :integer to Params::Integer" do
        type = described_class.resolve(:integer)
        expect(type).to eq(described_class::Params::Integer)
      end

      it "resolves :int to Params::Integer" do
        type = described_class.resolve(:int)
        expect(type).to eq(described_class::Params::Integer)
      end

      it "resolves :float to Params::Float" do
        type = described_class.resolve(:float)
        expect(type).to eq(described_class::Params::Float)
      end

      it "resolves :decimal to Params::Decimal" do
        type = described_class.resolve(:decimal)
        expect(type).to eq(described_class::Params::Decimal)
      end

      it "resolves :boolean to Params::Bool" do
        type = described_class.resolve(:boolean)
        expect(type).to eq(described_class::Params::Bool)
      end

      it "resolves :bool to Params::Bool" do
        type = described_class.resolve(:bool)
        expect(type).to eq(described_class::Params::Bool)
      end

      it "resolves :date to Params::Date" do
        type = described_class.resolve(:date)
        expect(type).to eq(described_class::Params::Date)
      end

      it "resolves :datetime to Params::DateTime" do
        type = described_class.resolve(:datetime)
        expect(type).to eq(described_class::Params::DateTime)
      end

      it "resolves :time to Params::Time" do
        type = described_class.resolve(:time)
        expect(type).to eq(described_class::Params::Time)
      end

      it "resolves :array to Params::Array" do
        type = described_class.resolve(:array)
        expect(type).to eq(described_class::Params::Array)
      end

      it "resolves :hash to Params::Hash" do
        type = described_class.resolve(:hash)
        expect(type).to eq(described_class::Params::Hash)
      end

      it "resolves :symbol to Symbol" do
        type = described_class.resolve(:symbol)
        expect(type).to eq(described_class::Symbol)
      end

      it "resolves :sym to Symbol" do
        type = described_class.resolve(:sym)
        expect(type).to eq(described_class::Symbol)
      end

      it "resolves :any to Any" do
        type = described_class.resolve(:any)
        expect(type).to eq(described_class::Any)
      end

      it "resolves :nil to Any" do
        type = described_class.resolve(:nil)
        expect(type).to eq(described_class::Any)
      end

      it "raises error for unknown symbol" do
        expect do
          described_class.resolve(:unknown_type)
        end.to raise_error(Expectant::ConfigurationError, /Unknown type symbol/)
      end
    end

    context "with Dry::Types::Type" do
      it "returns the type as-is" do
        dry_type = described_class::Strict::String
        result = described_class.resolve(dry_type)
        expect(result).to eq(dry_type)
      end

      it "preserves type constraints" do
        dry_type = described_class::Strict::String.constrained(min_size: 5)
        result = described_class.resolve(dry_type)
        expect(result).to eq(dry_type)
      end
    end

    context "with Class" do
      it "resolves to Instance type" do
        type = described_class.resolve(String)
        expect(type).to be_a(Dry::Types::Type)
        expect(type.call("test")).to eq("test")
      end

      it "validates class instances" do
        type = described_class.resolve(Array)
        expect(type.call([])).to eq([])
      end

      it "rejects non-instances" do
        type = described_class.resolve(String)
        expect { type.call(123) }.to raise_error(Dry::Types::ConstraintError)
      end
    end

    context "with invalid type definition" do
      it "raises ConfigurationError for numbers" do
        expect do
          described_class.resolve(123)
        end.to raise_error(Expectant::ConfigurationError, /Invalid type definition/)
      end

      it "raises ConfigurationError for hashes" do
        expect do
          described_class.resolve({})
        end.to raise_error(Expectant::ConfigurationError, /Invalid type definition/)
      end
    end
  end

  describe ".resolve_symbol" do
    it "is called by resolve for symbol types" do
      expect(described_class).to receive(:resolve_symbol).with(:string).and_call_original
      described_class.resolve(:string)
    end

    it "raises error for unknown symbols" do
      expect do
        described_class.resolve_symbol(:invalid)
      end.to raise_error(Expectant::ConfigurationError, /Unknown type symbol/)
    end
  end

  describe "type coercion" do
    context "with Params types" do
      it "coerces string to integer" do
        type = described_class.resolve(:integer)
        expect(type.call("123")).to eq(123)
      end

      it "coerces string to float" do
        type = described_class.resolve(:float)
        expect(type.call("123.45")).to eq(123.45)
      end

      it "coerces to boolean" do
        type = described_class.resolve(:bool)
        expect(type.call("true")).to eq(true)
        expect(type.call("false")).to eq(false)
      end

      it "coerces string to date" do
        type = described_class.resolve(:date)
        result = type.call("2024-01-01")
        expect(result).to be_a(Date)
        expect(result.to_s).to eq("2024-01-01")
      end
    end
  end
end
