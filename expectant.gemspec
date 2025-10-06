# frozen_string_literal: true

require_relative "lib/expectant/version"

Gem::Specification.new do |spec|
  spec.name = "expectant"
  spec.version = Expectant::VERSION
  spec.authors = ["Hector Medina Fetterman"]
  spec.email = ["javi@digitalhospital.com"]

  spec.summary = "A flexible DSL for defining reusable validation schemas"
  spec.description = "Expectant provides a clean DSL for defining multiple validation schemas in a single class. Built on dry-validation and dry-types, it supports custom rules, defaults, fallbacks, and context-aware validations, making it easy to validate inputs, outputs, and any structured data in your Ruby applications."
  spec.homepage = "https://github.com/DigitalHospital/expectant"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/DigitalHospital/expectant"
  spec.metadata["changelog_uri"] = "https://github.com/DigitalHospital/expectant"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-validation", "~> 1.10"
  spec.add_dependency "dry-types", "~> 1.7"
end
