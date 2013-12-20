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

class TestAsync < MiniTest::Test

  def test_result_object_provides_enough_info
    obj = Couchbase::Result.new
    assert obj.respond_to?(:success?)
    assert obj.respond_to?(:error)
    assert obj.respond_to?(:key)
    assert obj.respond_to?(:value)
    assert obj.respond_to?(:node)
    assert obj.respond_to?(:cas)
  end

  def test_it_requires_block_for_running_loop
    refute cb.async?
    assert_raises(LocalJumpError) do
      cb.run
    end
    cb.run do |conn|
      assert conn.async?
    end
  end

  def test_it_resets_async_flag_when_raising_exception_from_callback
    assert_raises(RuntimeError) do
      cb.run do |conn|
        conn.set(uniq_id, "foo") { raise }
      end
    end
    refute cb.async?
  end

  def test_nested_async_get_set
    cb.set(uniq_id, {"bar" => 1})
    cb.set(uniq_id(:hit), 0)

    cb.run do |conn|
      conn.get(uniq_id) do
        conn.get(uniq_id(:hit)) do |res|
          conn.set(uniq_id(:hit), res.value + 1)
        end
      end
    end

    val = cb.get(uniq_id(:hit))
    assert_equal 1, val
  end

  def test_nested_async_set_get
    val = nil

    cb.run do |conn|
      conn.set(uniq_id, "foo") do
        conn.get(uniq_id) do |res|
          val = res.value
        end
      end
    end

    assert_equal "foo", val
  end

  def test_nested_async_touch_get
    cb.set(uniq_id, "foo")
    success = false
    val = nil

    cb.run do |conn|
      conn.touch(uniq_id, :ttl => 1) do |res1|
        success = res1.success?
        conn.get(uniq_id) do |res2|
          val = res2.value
        end
      end
    end

    assert success
    assert_equal "foo", val
    sleep(2)
    assert_raises(Couchbase::Error::NotFound) do
      cb.get(uniq_id)
    end
  end

  def test_nested_async_delete_get
    cas = cb.set(uniq_id, "foo")
    success = false
    val = :unknown

    cb.run do |conn|
      conn.delete(uniq_id, :cas => cas) do |res1|
        success = res1.success?
        conn.get(uniq_id, :quiet => true) do |res2|
          val = res2.value
        end
      end
    end

    assert success
    refute val
  end

  def test_nested_async_stats_set
    skip
    stats = {}

    cb.run do |conn|
      conn.stats do |res1|
        id = uniq_id(res1.node, res1.key)
        stats[id] = false
        conn.set(id, res1.value) do |res2|
          stats[id] = res2.cas
        end
      end
    end

    stats.keys.each do |key|
      assert stats[key].is_a?(Numeric)
    end
  end

  def test_nested_async_flush_set
    skip
    cas = cb.set(uniq_id, "foo")
    res = {}

    cb.run do |conn|
      conn.flush do |res1|
        assert res1.success?, "Expected: successful status code.\nActual: #{res1.error.inspect}"
        id = uniq_id(res1.node)
        res[id] = false
        conn.set(id, true) do |res2|
          res[id] = res2.cas
        end
      end
    end

    assert_raises(Couchbase::Error::NotFound) do
      cb.get(uniq_id)
    end
    res.keys.each do |key|
      assert res[key].is_a?(Numeric)
      assert cb.get(key)
    end
  end

  def test_nested_async_incr_get
    skip
    cas = cb.set(uniq_id, 1)
    val = nil

    cb.run do |conn|
      conn.incr(uniq_id) do
        conn.get(uniq_id) do |res|
          val = res.value
        end
      end
    end

    assert_equal 2, val
  end

  def test_it_doesnt_accept_callbacks_in_synchronous_mode
    refute cb.async?

    assert_raises(ArgumentError) { cb.add(uniq_id, "foo") {} }
    assert_raises(ArgumentError) { cb.set(uniq_id, "foo") {} }
    assert_raises(ArgumentError) { cb.replace(uniq_id, "foo") {} }
    assert_raises(ArgumentError) { cb.get(uniq_id) {} }
    assert_raises(ArgumentError) { cb.touch(uniq_id) {} }
    assert_raises(ArgumentError) { cb.incr(uniq_id) {} }
    assert_raises(ArgumentError) { cb.decr(uniq_id) {} }
    assert_raises(ArgumentError) { cb.delete(uniq_id) {} }
    assert_raises(ArgumentError) { cb.append(uniq_id, "bar") {} }
    assert_raises(ArgumentError) { cb.prepend(uniq_id, "bar") {} }
    assert_raises(ArgumentError) { cb.stats {} }
  end

  def test_it_disallow_nested_run
    assert_raises(Couchbase::Error::Invalid) do
      cb.run do
        cb.run do
        end
      end
    end
  end

  def test_it_extends_timeout_in_async_mode_if_needed
    skip
    cb.set(uniq_id, "foo")

    cb.timeout = 100_000  # 100_000 us
    cb.run do
      cb.get(uniq_id) do |ret|
        assert ret.success?
        assert_equal "foo", ret.value
      end
      sleep(1.5)  # 1_500_000 us
    end
  end

  def test_send_threshold
    skip
    sent = false
    cb.run(:send_threshold => 100) do # 100 bytes
      cb.set(uniq_id, "foo" * 100) {|r| sent = true}
      assert sent
    end
  end

  def test_asynchronous_connection
    skip
    connection = Couchbase.new(:hostname => @mock.host, :port => @mock.port, :async => true)
    refute cb.connected?, "new asynchronous connection must be disconnected"
    cb.on_connect do |res|
      assert res.success?, "on_connect called with error #{res.error.inspect}"
      assert_same connection, res.bucket
    end
    cb.run {}
    assert cb.connected?, "it should be connected after first run"
  end

  def test_it_calls_callback_immediately_if_connected_sync
    skip
    assert cb.connected?, "connection wasn't established in sync mode"
    called = false
    cb.on_connect do |res|
      assert res.success?, "on_connect called with error #{res.error.inspect}"
      called = true
    end
    assert called, "the callback hasn't been called on set"
    called = false
    cb.on_connect do |res|
      assert res.success?, "on_connect called with error #{res.error.inspect}"
      called = true
    end
    refute called, "the callback must not be called on subsequent sets"
  end

  def test_it_calls_callback_immediately_if_connected_async
    skip
    connection = Couchbase.new(:hostname => @mock.host, :port => @mock.port, :async => true)
    refute cb.connected?, "new asynchronous connection must be disconnected"
    called = false
    cb.run {}
    assert cb.connected?, "the connection must be established"
    cb.run do
      cb.on_connect do |res|
        assert res.success?, "on_connect called with error #{res.error.inspect}"
        called = true
      end
    end
    assert called, "the callback hasn't been called on set"
    called = false
    cb.run do
      cb.on_connect do |res|
        assert res.success?, "on_connect called with error #{res.error.inspect}"
        called = true
      end
    end
    refute called, "the callback must not be called on subsequent sets"
  end

  def test_it_returns_error_if_user_start_work_on_disconnected_instance_outside_on_connect_callback
    skip
    connection = Couchbase.new(:hostname => @mock.host, :port => @mock.port, :async => true)
    refute cb.connected?, "new asynchronous connection must be disconnected"
    error = nil
    cb.on_error do |ex|
      error = ex
    end
    cb.run do |c|
      c.set("foo", "bar")
    end
    assert_instance_of(Couchbase::Error::Connect, error)
  end
end
