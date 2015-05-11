# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'couchbase/version'

Gem::Specification.new do |s|
  s.name          = 'couchbase-jruby-client'
  s.version       = Couchbase::VERSION
  s.authors       = ['Mike Evans']
  s.email         = ['mike@urlgonomics.com']
  s.description   = %q{Couchbase JRuby driver}
  s.summary       = %q{The unofficial jruby client library for use with Couchbase Server.}
  s.homepage      = 'https://github.com/mje113/couchbase-jruby-client'
  s.license       = 'Apache'
  s.platform      = 'java'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_runtime_dependency 'multi_json'
  s.add_runtime_dependency 'jbundler'
  spec.requirements << "jar 'com.couchbase:java-client', '2.1.1'"

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'jrjackson'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rubocop'
end
