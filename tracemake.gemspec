# frozen_string_literal: true

require_relative "lib/tracemake/version"

Gem::Specification.new do |spec|
  spec.name          = "tracemake"
  spec.version       = Tracemake::VERSION
  spec.authors       = ["kateinoigakukun"]
  spec.email         = ["kateinoigakukun@gmail.com"]

  spec.summary       = "A tool to trace make command execution and convert it to Chrome Tracing format"
  spec.description   = "This gem allows tracking the execution time of each command in a make process by converting the trace to Chrome Tracing format"
  spec.homepage      = "https://github.com/kateinoigakukun/tracemake"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6.0"
  spec.platform      = Gem::Platform::RUBY

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kateinoigakukun/tracemake"
  spec.metadata["changelog_uri"] = "https://github.com/kateinoigakukun/tracemake/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = ["tracemake"]
  spec.require_paths = ["lib"]

  spec.add_dependency "json", "~> 2.0"
end
