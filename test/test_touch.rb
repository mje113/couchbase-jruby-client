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

class TestTouch < Minitest::Test

  def test_trivial_touch
    cb.set(uniq_id, "bar", :ttl => 1)
    cb.touch(uniq_id, :ttl => 2)
    sleep(1)
    assert cb.get(uniq_id)
    sleep(2)
    assert_raises(Couchbase::Error::NotFound) do
      cb.get(uniq_id)
    end
  end

  def test_multi_touch
    cb.set(uniq_id(1), "bar")
    cb.set(uniq_id(2), "baz")
    ret = cb.touch(uniq_id(1) => 1, uniq_id(2) => 1)
    assert ret[uniq_id(1)]
    assert ret[uniq_id(2)]
    sleep(2)
    assert_raises(Couchbase::Error::NotFound) do
      cb.get(uniq_id(1))
    end
    assert_raises(Couchbase::Error::NotFound) do
      cb.get(uniq_id(2))
    end
  end

  def test_it_uses_default_ttl_for_touch
    cb.default_ttl = 1
    cb.set(uniq_id, "bar", :ttl => 10)
    cb.touch(uniq_id)
    sleep(2)
    assert_raises(Couchbase::Error::NotFound) do
      cb.get(uniq_id)
    end
  ensure
    cb.default_ttl = 0
  end

  def test_it_accepts_ttl_for_get_command
    cb.set(uniq_id, "bar", :ttl => 10)
    val = cb.get(uniq_id, :ttl => 1)
    assert_equal "bar", val
    sleep(2)
    assert_raises(Couchbase::Error::NotFound) do
      cb.get(uniq_id)
    end
  end

  def test_missing_in_quiet_mode
    cb.quiet = true
    cas1 = cb.set(uniq_id(1), "foo1")
    cas2 = cb.set(uniq_id(2), "foo2")

    assert_raises(Couchbase::Error::NotFound) do
      cb.touch(uniq_id(:missing), :quiet => false)
    end

    val = cb.touch(uniq_id(:missing))
    refute(val)

    ret = cb.touch(uniq_id(1), uniq_id(:missing), uniq_id(2))
    assert_equal true, ret[uniq_id(1)]
    assert_equal false, ret[uniq_id(:missing)]
    assert_equal true, ret[uniq_id(2)]
  ensure
    cb.quiet = false
  end

end
