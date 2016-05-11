# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wordstress/version'

Gem::Specification.new do |spec|
  spec.name          = "wordstress"
  spec.version       = Wordstress::VERSION
  spec.authors       = ["Paolo Perego", "markri"]
  spec.email         = ["paolo@wordstress.org"]
  spec.summary       = %q{wordstress is a security scanner for wordpress powered websites}
  spec.description   = %q{wordstress is a security scanner for wordpress powered websites. Site owners don't want to spend time in reading complex blackbox security scan
  reports trying to remove false positives. A useful security tool must give them only vulnerabilities really affecting installed plugins or themes. Please refere to the README file for further informations.}
  spec.homepage      = "http://wordstress.org"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency 'codesake-commons'
  spec.add_dependency 'json'
  spec.add_dependency 'ciphersurfer'
  spec.add_dependency 'terminal-table'

end
