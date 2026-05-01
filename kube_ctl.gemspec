# frozen_string_literal: true

require_relative 'lib/kube/ctl/version'

Gem::Specification.new do |spec|
  spec.name = 'kube_kubectl'
  spec.version = Kube::Ctl::VERSION
  spec.authors = ['Nathan K']
  spec.email = ['nathankidd@hey.com']

  spec.summary = 'Query builder for kubectl'

  spec.description = <<~DESC
    Clone the repo and run bin/rename-gem and you have a gem.
  DESC

  spec.homepage = 'https://github.com/general-intelligence-systems/kube_ctl'
  spec.license = 'Apache-2.0'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['documentation_uri'] = 'https://general-intelligence-systems.github.io/kube_ctl/'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'scampi', '~> 0.1'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 1.21'

  spec.add_dependency 'string_builder', "~> 1.2.2"
  spec.add_dependency 'debug', "~> 1.11"
  spec.add_dependency 'rubyshell', "~> 1.5"
  spec.add_dependency 'shellwords', "~> 0.2.2"
  spec.add_dependency 'json_schemer', "~> 2.5"
end
