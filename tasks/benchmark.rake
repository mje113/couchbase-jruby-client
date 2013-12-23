desc 'Run benchmarks'
task :benchmark do
  cd File.expand_path(File.join(__FILE__, '..', '..', 'test', 'profile')) do
    sh "bundle install && bundle exec ruby benchmark.rb | tee benchmark-#{RUBY_VERSION}p#{RUBY_PATCHLEVEL}.log"
  end
end
