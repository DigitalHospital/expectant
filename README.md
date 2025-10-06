# Expectant

<span>[![Gem Version](https://img.shields.io/gem/v/expectant?style=flat&label=Expectant)](https://rubygems.org/gems/expectant)</span>

A Ruby gem for defining flexible, reusable validation schemas with a clean DSL. Built on top of [dry-validation](https://dry-rb.org/gems/dry-validation/) and [dry-types](https://dry-rb.org/gems/dry-types/), Expectant lets you define multiple validation schemas in a single class with support for custom rules, defaults, fallbacks, and context-aware validations.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'expectant'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install expectant
```

## Usage

### Basic Example

```ruby
class InvoiceService
  include Expectant

  # Define a schema type
  expectation :expects

  # Define fields with types
  expects :customer_id, type: :integer
  expects :amount, type: :float
  expects :description, type: :string, optional: true
  expects :status, type: :string, default: "draft"

  # Define custom validation rules
  expects_rule(:amount) do
    key.failure("must be positive") if value && value <= 0
  end

  def process(input)
    result = validate(:expects, input)

    if result.success?
      # Process the validated data
      puts "Valid invoice: #{result.to_h}"
    else
      puts "Errors: #{result.errors.to_h}"
    end
  end
end

service = InvoiceService.new
service.process(customer_id: 123, amount: 100.0)
# => Valid invoice: {:customer_id=>123, :amount=>100.0, :status=>"draft"}

service.process(customer_id: 123, amount: -50.0)
# => Errors: {:amount=>["must be positive"]}
```

### Multiple Schemas

You can define multiple independent schemas in the same class:

```ruby
class DataProcessor
  include Expectant

  # Input validation schema
  expectation :inputs
  inputs :data, type: :hash
  inputs :format, type: :string, default: "json"

  inputs_rule(:format) do
    valid_formats = ["json", "xml", "csv"]
    key.failure("must be json, xml, or csv") unless valid_formats.include?(value)
  end

  # Output validation schema
  expectation :outputs
  outputs :result, type: :string
  outputs :timestamp, type: :datetime

  def process(input_data)
    # Validate inputs
    input_result = validate(:inputs, input_data)
    return input_result unless input_result.success?

    # Process data...
    output_data = {result: "processed", timestamp: Time.now}

    # Validate outputs
    validate(:outputs, output_data)
  end
end
```

### Supported Types

Expectant supports all dry-types through convenient symbols:

```ruby
expectation :fields

fields :name, type: :string          # String
fields :age, type: :integer          # Integer
fields :price, type: :float          # Float
fields :total, type: :decimal        # Decimal
fields :active, type: :boolean       # Boolean
fields :birth_date, type: :date      # Date
fields :created_at, type: :datetime  # DateTime
fields :started_at, type: :time      # Time
fields :tags, type: :array           # Array
fields :metadata, type: :hash        # Hash
fields :status, type: :symbol        # Symbol
fields :data, type: :any             # Any type

# Arrays of specific types
fields :names, type: [:array, :string]
fields :scores, type: [:array, :integer]

# Custom classes
fields :invoice, type: Invoice
fields :user, type: User
```

### Optional Fields and Defaults

```ruby
expectation :expects

# Optional field (can be nil or omitted)
expects :description, type: :string, optional: true

# Field with default value
expects :status, type: :string, default: "draft"
expects :discount, type: :float, default: 0.0

# Proc-based defaults (evaluated at runtime)
expects :created_at, type: :datetime, default: -> { Time.now }
expects :reference, type: :string, default: -> { SecureRandom.uuid }
```

### Fallback Values

Fallbacks provide a safety net when validation fails:

```ruby
expectation :pagination

pagination :page, type: :integer, default: 1, fallback: 1
pagination :per_page, type: :integer, default: 25, fallback: 25

pagination_rule(:page) do
  key.failure("must be positive") if value && value < 1
end

pagination_rule(:per_page) do
  key.failure("must be between 1-100") if value && (value < 1 || value > 100)
end

# If user provides per_page: 500, validation would normally fail
# But with fallback, it automatically uses 25 instead
service = MyService.new
result = service.validate(:pagination, {per_page: 500})
result.success? # => true
result.to_h[:per_page] # => 25
```

Fallbacks can also be procs:

```ruby
pagination :per_page, type: :integer, fallback: -> { self.class.default_per_page }
```

### Validation Rules

Define custom validation rules for single fields, multiple fields, or global rules:

```ruby
expectation :expects

expects :email, type: :string
expects :age, type: :integer
expects :kilometers, type: :float, optional: true
expects :miles, type: :float, optional: true

# Single field rule
expects_rule(:email) do
  key.failure("invalid email format") unless value&.include?("@")
end

expects_rule(:age) do
  key.failure("must be 18 or older") if value && value < 18
end

# Multiple field rule
expects_rule(:kilometers, :miles) do
  if key?(:kilometers) && key?(:miles)
    base.failure("provide either kilometers or miles, not both")
  end
end

# Global rule (no field specified)
expects_rule do
  if values[:start_date] && values[:end_date]
    if values[:start_date] > values[:end_date]
      base.failure("start_date must be before end_date")
    end
  end
end
```

### Context-Aware Validation

Pass external data to validation rules via context:

```ruby
class PaginationValidator
  include Expectant

  expectation :params

  params :page, type: :integer, default: 1
  params :per_page, type: :integer, default: 25
  params :order, type: :string, optional: true

  # Access context values in rules
  params_rule(:per_page) do
    max = context[:per_page_max] || 100
    key.failure("must be ≤ #{max}") if value && value > max
  end

  params_rule(:order) do
    valid_columns = context[:orderable_columns] || []
    if value && !valid_columns.include?(value)
      key.failure("must be a valid column")
    end
  end

  def validate_with_context(data, max:, columns:)
    validate(:params, data, context: {
      per_page_max: max,
      orderable_columns: columns
    })
  end
end

validator = PaginationValidator.new
result = validator.validate_with_context(
  {per_page: 50, order: "created_at"},
  max: 100,
  columns: ["id", "created_at", "updated_at"]
)
```

### Getting Schema Keys

Retrieve the field names for a schema:

```ruby
class MyService
  include Expectant

  expectation :expects
  expects :name, type: :string
  expects :age, type: :integer
end

MyService.schema_keys(:expects)
# => [:name, :age]
```

## Advanced Features

### Custom Schema Names

You can use any name for your schemas, not just `expects` and `promises`:

```ruby
class CustomValidator
  include Expectant

  expectation :request
  expectation :response
  expectation :metadata

  request :path, type: :string
  response :status, type: :integer
  metadata :timestamp, type: :datetime
end
```

### Working with Custom Classes

```ruby
class Invoice
  attr_accessor :id, :total
end

class InvoiceService
  include Expectant

  expectation :expects
  expects :invoice, type: Invoice

  expectation :promises
  promises :updated_invoice, type: Invoice

  expects_rule(:invoice) do
    key.failure("invoice must have an ID") unless value&.id
  end
end
```

### Combining Defaults, Fallbacks, and Validation

```ruby
class SmartValidator
  include Expectant

  expectation :config

  # Default value when not provided
  # Fallback value when validation fails
  config :timeout, type: :integer, default: 30, fallback: 30

  config_rule(:timeout) do
    if value && (value < 1 || value > 300)
      key.failure("must be between 1 and 300 seconds")
    end
  end
end

validator = SmartValidator.new

# No timeout provided -> uses default (30)
result = validator.validate(:config, {})
result.to_h[:timeout] # => 30

# Invalid timeout (500) -> uses fallback (30)
result = validator.validate(:config, {timeout: 500})
result.success? # => true
result.to_h[:timeout] # => 30

# Valid timeout -> uses provided value
result = validator.validate(:config, {timeout: 60})
result.to_h[:timeout] # => 60
```

## How It Works

Expectant provides a DSL that builds on top of dry-validation and dry-types:

1. **`expectation :name`** - Defines a new schema type and creates methods for defining fields and rules
2. **Schema methods** (e.g., `expects`, `promises`) - Define fields with types and options
3. **Rule methods** (e.g., `expects_rule`, `promises_rule`) - Define custom validation rules
4. **`validate(schema_name, data, context: {})`** - Validates data against a schema

Under the hood, Expectant:
- Converts your field definitions into dry-types
- Builds dry-validation contracts with your custom rules
- Handles default values and fallback logic automatically
- Manages context for complex validations

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/DigitalHospital/expectant.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
