# Author:: Couchbase <info@couchbase.com>
# Copyright:: 2011, 2012 Couchbase, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

rule 'test/CouchbaseMock.jar' do |task|
  jar_path = "0.6-SNAPSHOT/CouchbaseMock-0.6-20130903.160518-3.jar"
  sh %{wget -q -O test/CouchbaseMock.jar http://files.couchbase.com/maven2/org/couchbase/mock/CouchbaseMock/#{jar_path}}
end

task :test do
  $LOAD_PATH.unshift('lib', 'test')

  if ENV['TEST']
    require ENV['TEST']
  else
    Dir.glob('./test/**/test_*.rb') { |f| require f }
  end

  require 'test/setup.rb'
end

Rake::Task['test'].prerequisites.unshift('test/CouchbaseMock.jar')

