# frozen_string_literal: true

RSpec.describe Expectant::Utils do
  describe ".singularize" do
    it "singularizes plural words" do
      expect(described_class.singularize(:inputs)).to eq(:input)
      expect(described_class.singularize(:outputs)).to eq(:output)
      expect(described_class.singularize(:data)).to eq(:datum)
    end

    it "handles string input" do
      expect(described_class.singularize("inputs")).to eq(:input)
    end

    it "returns symbol" do
      result = described_class.singularize(:items)
      expect(result).to be_a(Symbol)
    end

    it "handles irregular plurals" do
      expect(described_class.singularize(:people)).to eq(:person)
      expect(described_class.singularize(:children)).to eq(:child)
    end

    it "handles already singular words" do
      result = described_class.singularize(:input)
      expect(result).to be_a(Symbol)
    end
  end

  describe ".validator_method_name" do
    let(:configuration) { Expectant::Configuration.new }

    context "with default configuration" do
      it "returns schema_name_suffix" do
        result = described_class.validator_method_name(:input, configuration)
        expect(result).to eq("input_rule")
      end
    end

    context "with custom suffix" do
      before do
        configuration.validator_suffix = "validation"
      end

      it "uses custom suffix" do
        result = described_class.validator_method_name(:input, configuration)
        expect(result).to eq("input_validation")
      end
    end

    context "with custom prefix" do
      before do
        configuration.validator_prefix = "validate"
        configuration.validator_suffix = nil
      end

      it "uses custom prefix" do
        result = described_class.validator_method_name(:input, configuration)
        expect(result).to eq("validate_input")
      end
    end

    context "with both prefix and suffix" do
      before do
        configuration.validator_prefix = "check"
        configuration.validator_suffix = "constraints"
      end

      it "uses both prefix and suffix" do
        result = described_class.validator_method_name(:input, configuration)
        expect(result).to eq("check_input_constraints")
      end
    end

    context "with nil suffix" do
      before do
        configuration.validator_suffix = nil
      end

      it "omits suffix" do
        result = described_class.validator_method_name(:input, configuration)
        expect(result).to eq("input")
      end
    end

    context "with nil prefix and suffix" do
      before do
        configuration.validator_prefix = nil
        configuration.validator_suffix = nil
      end

      it "returns just the schema name" do
        result = described_class.validator_method_name(:input, configuration)
        expect(result).to eq("input")
      end
    end
  end

  describe ".define_with_collision_policy" do
    let(:test_class) { Class.new }

    context "when method does not exist" do
      it "calls the block to define the method" do
        described_class.define_with_collision_policy(test_class.singleton_class, :new_method, collision: :error) do
          test_class.define_singleton_method(:new_method) { "defined" }
        end

        expect(test_class.new_method).to eq("defined")
      end
    end

    context "when method already exists" do
      before do
        test_class.define_singleton_method(:existing_method) { "original" }
      end

      context "with :error policy" do
        it "raises ConfigurationError" do
          expect do
            described_class.define_with_collision_policy(test_class.singleton_class, :existing_method, collision: :error) do
              test_class.define_singleton_method(:existing_method) { "new" }
            end
          end.to raise_error(Expectant::ConfigurationError, /already defined/)
        end
      end

      context "with :force policy" do
        it "removes existing method and calls block" do
          described_class.define_with_collision_policy(test_class.singleton_class, :existing_method, collision: :force) do
            test_class.define_singleton_method(:existing_method) { "replaced" }
          end

          expect(test_class.existing_method).to eq("replaced")
        end

        it "handles methods that cannot be removed gracefully" do
          # Mock remove_method to raise an error
          allow(test_class.singleton_class).to receive(:send).with(:remove_method, :existing_method).and_raise(StandardError, "Cannot remove")

          expect do
            described_class.define_with_collision_policy(test_class.singleton_class, :existing_method, collision: :force) do
              test_class.define_singleton_method(:existing_method) { "new" }
            end
          end.not_to raise_error

          # Verify the method was still defined
          expect(test_class.existing_method).to eq("new")
        end
      end

      context "with invalid policy" do
        it "raises ConfigurationError" do
          expect do
            described_class.define_with_collision_policy(test_class.singleton_class, :existing_method, collision: :invalid) do
              # block content
            end
          end.to raise_error(Expectant::ConfigurationError, /Unknown collision policy/)
        end
      end
    end

    context "with symbol method names" do
      it "converts string to symbol" do
        described_class.define_with_collision_policy(test_class.singleton_class, "string_method", collision: :error) do
          test_class.define_singleton_method(:string_method) { "works" }
        end

        expect(test_class.string_method).to eq("works")
      end
    end

    context "with private methods" do
      before do
        test_class.define_singleton_method(:private_method) { "private" }
        test_class.singleton_class.send(:private, :private_method)
      end

      it "detects private method collision with :error policy" do
        expect do
          described_class.define_with_collision_policy(test_class.singleton_class, :private_method, collision: :error) do
            # block
          end
        end.to raise_error(Expectant::ConfigurationError, /already defined/)
      end

      it "replaces private method with :force policy" do
        described_class.define_with_collision_policy(test_class.singleton_class, :private_method, collision: :force) do
          test_class.define_singleton_method(:private_method) { "replaced" }
        end

        expect(test_class.send(:private_method)).to eq("replaced")
      end
    end
  end
end
