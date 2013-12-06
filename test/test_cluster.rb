# Author:: Mike Evans <mike@urlgonomics.com>
# Copyright:: 2013 Urlgonomics LLC.
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
require File.join(File.dirname(__FILE__), 'setup')

class TestCluster < MiniTest::Test

  def setup
    @cluster = Couchbase::Cluster.new(username: 'admin', password: 'password')
  end

  def test_that_it_can_connect_to_cluster_manager
    assert @cluster
  end

  def test_can_list_buckets
    assert @cluster.list_buckets.include?('default')
  end

end