Gem::Specification.new do |spec|
  spec.name          = "xml_data_extractor"
  spec.version       = "0.5.0"
  spec.authors       = ["Fernando Almeida"]
  spec.email         = ["fernandoprsbr@gmail.com"]

  spec.summary       = "Provides a simples DSL for extracting data from XML documents"
  spec.homepage      = "https://github.com/monde-sistemas/xml_data_extractor"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.0"
  spec.add_dependency "activesupport", "~> 6.0"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
