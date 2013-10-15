# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'couchbase/version'

Gem::Specification.new do |s|
  s.name          = 'couchbase-jruby-client'
  s.version       = Couchbase::VERSION
  s.authors       = ['Mike Evans']
  s.email         = ['mike@urlgonomics.com']
  s.description   = %q{Couchbase jruby driver}
  s.summary       = %q{The unofficial jruby client library for use with Couchbase Server.}
  s.homepage      = ''
  s.license       = 'MIT'
  s.platform      = Gem::Platform::JAVA

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']


  # s.add_runtime_dependency 'json-jruby'
  s.add_runtime_dependency 'multi_json',   '~> 1.0'
  s.add_runtime_dependency 'atomic',       '~> 1.1.14'

  s.add_development_dependency 'bundler',  '~> 1.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest', '~> 5.0.4'
  s.add_development_dependency 'active_support'
  s.add_development_dependency 'pry'
end

# $:.push File.expand_path('../lib', __FILE__)
# require 'couchbase/version'

# Gem::Specification.new do |s|
#   s.name        = 'couchbase'
#   s.version     = Couchbase::VERSION
#   s.author      = 'Couchbase'
#   s.email       = 'support@couchbase.com'
#   s.license     = 'ASL-2'
#   s.homepage    = 'http://couchbase.org'
#   s.summary     = %q{Couchbase ruby driver}
#   s.description = %q{The official client library for use with Couchbase Server.}

#   s.files         = `git ls-files`.split('\n')
#   s.test_files    = `git ls-files -- {test,spec,features}/*`.split('\n')
#   s.executables   = `git ls-files -- bin/*`.split('\n').map{ |f| File.basename(f) }
#   s.extensions    = `git ls-files -- ext/**/extconf.rb`.split('\n')
#   s.require_paths = ['lib']

#   s.add_runtime_dependency 'yaji', '~> 0.3.2'
#   s.add_runtime_dependency 'multi_json', '~> 1.0'
#   s.add_runtime_dependency 'connection_pool', '~> 1.0.0'

#   s.add_development_dependency 'rake'
#   s.add_development_dependency 'minitest', '~> 5.0.4'
#   s.add_development_dependency 'rake-compiler', '>= 0.7.5'
#   s.add_development_dependency 'mini_portile'
#   s.add_development_dependency 'yajl-ruby', '~> 1.1.0'
#   s.add_development_dependency 'active_support'
#   s.add_development_dependency 'eventmachine'
# end
