# Expectant

[![Gem Version](https://img.shields.io/gem/v/expectant?style=flat&label=Expectant)](https://rubygems.org/gems/expectant)
[![Ruby Test](https://github.com/DigitalHospital/expectant/actions/workflows/main.yml/badge.svg?branch=master)](https://github.com/expectant/actions/workflows/main.yml)</span> 

A Ruby DSL for defining validation schemas with type coercion, defaults, and fallbacks. Built on [dry-validation](https://dry-rb.org/gems/dry-validation/) and [dry-types](https://dry-rb.org/gems/dry-types/).

## Installation

```ruby
gem 'expectant'
```

## Quick Start

```ruby
class InvoiceService
  include Expectant::DSL

  expects :inputs

  input :customer_id, type: :integer
  input :amount, type: :float
  input :status, type: :string, default: "draft"
  input :description, type: :string, optional: true

  input_rule(:amount) do
    key.failure("must be positive") if value && value <= 0
  end

  def process(data)
    result = inputs.validate(data)

    if result.success?
      # Use validated data: result.to_h
    else
      # Handle errors: result.errors.to_h
    end
  end
end
```

## Core Features

### Types

```ruby
expects :inputs

input :name, type: :string
input :age, type: :integer
input :price, type: :float
input :active, type: :boolean
input :date, type: :date
input :time, type: :datetime
input :data, type: :hash
input :tags, type: :array
input :user, type: User  # Custom class
```

### Defaults and Optional Fields

```ruby
# Optional (can be omitted)
input :description, type: :string, optional: true

# Static default
input :status, type: :string, default: "draft"

# Dynamic default (proc)
input :created_at, type: :datetime, default: -> { Time.now }
```

### Fallbacks

Automatically substitute values when validation fails:

```ruby
input :per_page, type: :integer, default: 25, fallback: 25

input_rule(:per_page) do
  key.failure("max 100") if value && value > 100
end

# If per_page: 500 is provided, validation succeeds with fallback value 25
```

### Validation Rules

```ruby
# Single field
input_rule(:email) do
  key.failure("invalid") unless value&.include?("@")
end

# Multiple fields
input_rule(:start_date, :end_date) do
  base.failure("start must be before end") if values[:start_date] > values[:end_date]
end

# Global rule
input_rule do
  base.failure("error") if some_condition
end
```

### Context

```ruby
input_rule(:order) do
  valid = context[:orderable_columns] || []
  key.failure("invalid column") unless valid.include?(value)
end

# Pass context when validating
inputs.validate(data, context: { orderable_columns: ["id", "name"] })
```

### Multiple Schemas

```ruby
expects :inputs
expects :outputs

input :data, type: :hash
output :result, type: :string

inputs.validate(input_data)
outputs.validate(output_data)
```

## Configuration

Customize validator method names:

```ruby
Expectant.configure do |config|
  config.validator_suffix = "validation"  # input_validation instead of input_rule
  config.validator_prefix = "validate"    # validate_input
end
```

## Development

```bash
bundle install
bundle exec rspec
```

## License

MIT License
