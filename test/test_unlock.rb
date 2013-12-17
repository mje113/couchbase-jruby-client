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

require File.join(File.dirname(__FILE__), 'setup')

class TestUnlock < MiniTest::Test

  def test_trivial_unlock
    cb.set(uniq_id, "foo")
    _, _, cas = cb.get(uniq_id, :lock => true, :extended => true)
    assert_raises Couchbase::Error::KeyExists do
      cb.set(uniq_id, "bar")
    end
    assert cb.unlock(uniq_id, :cas => cas)
    cb.set(uniq_id, "bar")
  end

  def test_alternative_syntax_for_single_key
    cb.set(uniq_id, "foo")
    _, _, cas = cb.get(uniq_id, :lock => true, :extended => true)
    assert_raises Couchbase::Error::KeyExists do
      cb.set(uniq_id, "bar")
    end
    assert cb.unlock(uniq_id, cas)
    cb.set(uniq_id, "bar")
  end

  def test_multiple_unlock
    skip
    cb.set(uniq_id(1), "foo")
    cb.set(uniq_id(2), "foo")
    info = cb.get(uniq_id(1), uniq_id(2), :lock => true, :extended => true)
    assert_raises Couchbase::Error::KeyExists do
      cb.set(uniq_id(1), "bar")
    end
    assert_raises Couchbase::Error::KeyExists do
      cb.set(uniq_id(2), "bar")
    end
    ret = cb.unlock(uniq_id(1) => info[uniq_id(1)][2],
                            uniq_id(2) => info[uniq_id(2)][2])
    assert ret[uniq_id(1)]
    assert ret[uniq_id(2)]
    cb.set(uniq_id(1), "bar")
    cb.set(uniq_id(2), "bar")
  end

  def test_quiet_mode
    skip
    cb.set(uniq_id, "foo")
    _, _, cas = cb.get(uniq_id, :lock => true, :extended => true)
    assert_raises Couchbase::Error::NotFound do
      cb.unlock(uniq_id(:missing), :cas => 0xdeadbeef)
    end
    keys = {
      uniq_id => cas,
      uniq_id(:missing) => 0xdeadbeef
    }
    ret = cb.unlock(keys, :quiet => true)
    assert ret[uniq_id]
    refute ret[uniq_id(:missing)]
  end

  def test_tmp_failure
    skip unless $mock.real?
    cas1 = cb.set(uniq_id(1), "foo")
    cas2 = cb.set(uniq_id(2), "foo")
    cb.get(uniq_id(1), :lock => true) # get with lock will update CAS
    assert_raises Couchbase::Error::TemporaryFail do
      cb.unlock(uniq_id(1), cas1)
    end
    assert_raises Couchbase::Error::TemporaryFail do
      cb.unlock(uniq_id(2), cas2)
    end
  end
end
