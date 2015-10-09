require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

module Bundler
  class GemHelper
    unless method_defined?(:rubygem_push)
      raise NoMethodError, 'Monkey patching Bundler::GemHelper#rubygem_push failed: did the Bundler API change???'
    end

    def rubygem_push(path)
      gem_server_url = 'http://162.150.185.166'
      sh %{gem push #{path} --host #{gem_server_url}}

      Bundler.ui.confirm "Pushed #{name} #{version} to #{gem_server_url}"
    end
  end
end

task default: :test

task :pry do
  require 'couchbase'
  require 'pry'
  Pry.start
end
