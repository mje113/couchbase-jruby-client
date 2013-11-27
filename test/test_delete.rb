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

class TestDelete < MiniTest::Test

  def test_trivial_delete
    cb.set(uniq_id, "bar")
    assert cb.delete(uniq_id)
    assert_raises(Couchbase::Error::NotFound) do
      cb.delete(uniq_id)
    end
  end

  def test_delete_missing
    assert_raises(Couchbase::Error::NotFound) do
      cb.delete(uniq_id(:missing))
    end
    refute cb.delete(uniq_id(:missing), :quiet => true)
    refute cb.quiet?
    cb.quiet = true
    refute cb.delete(uniq_id(:missing))
  end

  def test_delete_with_cas
    skip
    cas = cb.set(uniq_id, "bar")
    missing_cas = cas - 1
    assert_raises(Couchbase::Error::KeyExists) do
      cb.delete(uniq_id, :cas => missing_cas)
    end
    assert cb.delete(uniq_id, :cas => cas)
  end

  def test_allow_fixnum_as_cas_parameter
    cas = cb.set(uniq_id, "bar")
    assert cb.delete(uniq_id, cas)
  end

  def test_delete_with_prefix
    skip
    connection = Couchbase.new(:hostname => @mock.host, :port => @mock.port, :key_prefix => "prefix:")
    cb.set(uniq_id(:foo), "bar")
    assert cb.delete(uniq_id(:foo))
    assert_raises(Couchbase::Error::NotFound) do
      cb.get(uniq_id(:foo))
    end
  end

  def test_simple_multi_delete
    cb.quiet = true
    cb.set(uniq_id(1) => "bar", uniq_id(2) => "foo")
    res = cb.delete(uniq_id(1), uniq_id(2))
    assert res.is_a?(Hash)
    assert res[uniq_id(1)]
    assert res[uniq_id(2)]
  ensure
    cb.quiet = false
  end

  def test_simple_multi_delete_missing
    cb.quiet = true
    cb.set(uniq_id(1) => "bar", uniq_id(2) => "foo")
    res = cb.delete(uniq_id(1), uniq_id(:missing), :quiet => true)
    assert res.is_a?(Hash)
    assert res[uniq_id(1)]
    refute res[uniq_id(:missing)]
  ensure
    cb.quiet = false
  end

  def test_multi_delete_with_cas_check
    skip
    cb.quiet = true
    cas = cb.set(uniq_id(1) => "bar", uniq_id(2) => "foo")
    res = cb.delete(uniq_id(1) => cas[uniq_id(1)], uniq_id(2) => cas[uniq_id(2)])
    assert res.is_a?(Hash)
    assert res[uniq_id(1)]
    assert res[uniq_id(2)]
  ensure
    cb.quiet = false
  end

  def test_multi_delete_missing_with_cas_check
    skip
    cb.quiet = true
    cas = cb.set(uniq_id(1) => "bar", uniq_id(2) => "foo")
    res = cb.delete(uniq_id(1) => cas[uniq_id(1)], uniq_id(:missing) => cas[uniq_id(2)])
    assert res.is_a?(Hash)
    assert res[uniq_id(1)]
    refute res[uniq_id(:missing)]
  ensure
    cb.quiet = false
  end

  def test_multi_delete_with_cas_check_mismatch
    skip
    cb.quiet = true
    cas = cb.set(uniq_id(1) => "bar", uniq_id(2) => "foo")

    assert_raises(Couchbase::Error::KeyExists) do
      cb.delete(uniq_id(1) => cas[uniq_id(1)] + 1,
                        uniq_id(2) => cas[uniq_id(2)])
    end
  ensure
    cb.quiet = false
  end
end
