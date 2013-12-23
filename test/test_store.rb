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

class TestStore < MiniTest::Test

  def test_trivial_set
    cas = cb.set(uniq_id, "bar")
    assert(cas > 0)
  end

  def test_set_with_cas
    cas1 = cb.set(uniq_id, "bar1")
    assert cas1 > 0

    assert_raises(Couchbase::Error::KeyExists) do
      cb.set(uniq_id, "bar2", :cas => cas1+1)
    end

    cas2 = cb.set(uniq_id, "bar2", :cas => cas1)
    assert cas2 > 0
    refute_equal cas2, cas1

    cas3 = cb.set(uniq_id, "bar3")
    assert cas3 > 0
    refute_equal cas3, cas2
    refute_equal cas3, cas1
  end

  def test_add
    cas1 = cb.add(uniq_id, "bar")
    assert cas1 > 0

    assert_raises(Couchbase::Error::KeyExists) do
      cb.add(uniq_id, "bar")
    end

    assert_raises(Couchbase::Error::KeyExists) do
      cb.add(uniq_id, "bar", :cas => cas1)
    end
  end

  def test_replace
    assert_raises(Couchbase::Error::NotFound) do
      cb.replace(uniq_id, "bar")
    end

    cas1 = cb.set(uniq_id, "bar")
    assert cas1 > 0

    cb.replace(uniq_id, "bar")
  end

  def test_acceptable_keys
    cas = cb.set(uniq_id.to_sym, "bar")
    assert cas > 0

    cas = cb.set(uniq_id.to_s, "bar")
    assert cas > 0

    assert_raises(TypeError) do
      cb.set(nil, "bar")
    end

    obj = {:foo => "bar", :baz => 1}
    assert_raises(TypeError) do
      cb.set(obj, "bar")
    end

    class << obj
      alias :to_str :to_s
    end

    cb.set(obj, "bar")
    assert cas > 0
  end

  def test_asynchronous_set
    ret = nil
    future = cb.async_set(uniq_id, "foo1") { |res| ret = res }
    future.get
    sleep 0.1

    assert ret.is_a?(Couchbase::Result)
    assert ret.success?
    assert_equal uniq_id, ret.key
    assert_equal :set, ret.operation
    assert ret.cas.is_a?(Numeric)
  end

    def test_asynchronous_set_wtihout_block
    future = cb.async_set(uniq_id, 'fu')
    future.get
    sleep 0.1

    assert_equal 'fu', cb.get(uniq_id)
  end

  def test_it_raises_error_when_appending_or_prepending_to_missing_key
    assert_raises(Couchbase::Error::NotStored) do
      cb.append(uniq_id(:missing), "foo")
    end

    assert_raises(Couchbase::Error::NotStored) do
      cb.prepend(uniq_id(:missing), "foo")
    end
  end

  def test_append
    cas1 = cb.set(uniq_id, "foo", format: :plain)
    assert cas1 > 0
    cas2 = cb.append(uniq_id, "bar")
    assert cas2 > 0
    refute_equal cas2, cas1

    val = cb.get(uniq_id)
    assert_equal "foobar", val
  end

  def test_prepend
    cb.default_format = :plain

    cas1 = cb.set(uniq_id, "foo")
    assert cas1 > 0
    cas2 = cb.prepend(uniq_id, "bar")
    assert cas2 > 0
    refute_equal cas2, cas1

    val = cb.get(uniq_id)
    assert_equal "barfoo", val
  ensure
    cb.default_format = :document
  end

  def test_set_with_prefix
    skip
    connection = Couchbase.new(:hostname => @mock.host, :port => @mock.port, :key_prefix => "prefix:")
    cb.set(uniq_id(:foo), "bar")
    assert_equal "bar", cb.get(uniq_id(:foo))
    expected = {uniq_id(:foo) => "bar"}
    assert_equal expected, cb.get(uniq_id(:foo), :assemble_hash => true)

    connection = Couchbase.new(:hostname => @mock.host, :port => @mock.port, :key_prefix => nil)
    expected = {"prefix:#{uniq_id(:foo)}" => "bar"}
    assert_equal expected, cb.get("prefix:#{uniq_id(:foo)}", :assemble_hash => true)
  end

  ArbitraryData = Struct.new(:baz)

  def test_set_with_marshal
    cb.set(uniq_id, ArbitraryData.new('thing'), format: :marshal)
    val = cb.get(uniq_id)
    assert val.is_a?(ArbitraryData)
    assert_equal "thing", val.baz
  end

  def test_set_using_brackets
    cb[uniq_id(1)] = "foo"
    val = cb.get(uniq_id(1))
    assert_equal "foo", val

    cb[uniq_id(3), :format => :marshal] = ArbitraryData.new("thing")
    val = cb.get(uniq_id(3))
    assert val.is_a?(ArbitraryData)
    assert_equal "thing", val.baz
  end

  def test_multi_store
    cb.default_format = :plain
    cb.add(uniq_id(:a) => "bbb", uniq_id(:z) => "yyy")
    assert_equal ["bbb", "yyy"], cb.get(uniq_id(:a), uniq_id(:z))

    # cb.prepend(uniq_id(:a) => "aaa", uniq_id(:z) => "xxx")
    # assert_equal ["aaabbb", "xxxyyy"], cb.get(uniq_id(:a), uniq_id(:z))

    # cb.append(uniq_id(:a) => "ccc", uniq_id(:z) => "zzz")
    # assert_equal ["aaabbbccc", "xxxyyyzzz"], cb.get(uniq_id(:a), uniq_id(:z))

    # cb.replace(uniq_id(:a) => "foo", uniq_id(:z) => "bar")
    # assert_equal ["foo", "bar"], cb.get(uniq_id(:a), uniq_id(:z))

    res = cb.set(uniq_id(:a) => "bar", uniq_id(:z) => "foo")
    assert_equal ["bar", "foo"], cb.get(uniq_id(:a), uniq_id(:z))
    assert res.is_a?(Hash)
  ensure
    cb.default_format = :document
  end
end
