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

class TestBucket < MiniTest::Test

  def test_it_substitute_default_parts_to_url
    with_configs(:host => 'localhost') do |configs| # pick first free port
      connections = [
        Couchbase.new("http://#{configs.host}:#{configs.port}"),
        Couchbase.new(:port => configs.port),
        Couchbase.new("http://#{configs.host}:8091", :port => configs.port)
      ]
      connections.each do |connection|
        assert_equal configs.port, connection.port
        assert_equal "#{configs.host}:#{configs.port}", connection.authority
        assert_equal "http://#{configs.host}:#{configs.port}/pools/default/buckets/default/", connection.url
      end
      connections.each(&:disconnect)
    end

    with_configs(:host => '127.0.0.1') do |configs|
      connections = [
        Couchbase.new("http://#{configs.host}:#{configs.port}"),
        Couchbase.new(:hostname => configs.host, :port => configs.port),
        Couchbase.new('http://example.com:8091', :hostname => configs.host, :port => configs.port)
      ]
      connections.each do |connection|
        assert_equal configs.host, connection.hostname
        assert_equal "#{configs.host}:#{configs.port}", connection.authority
        assert_equal "http://#{configs.host}:#{configs.port}/pools/default/buckets/default/", connection.url
      end
      connections.each(&:disconnect)
    end
  end

  def test_it_raises_network_error_if_server_not_found
    skip 'Exception not being trapped correctly'
    refute(`netstat -tnl` =~ /12345/)
    assert_raises Couchbase::Error::Connect do
      Couchbase.new(:port => 12345)
    end
  end

  def test_it_raises_argument_error_for_illegal_url
    illegal = [
      "ftp://localhost:8091/",
      "http:/localhost:8091/",
      ""
    ]
    illegal.each do |url|
      assert_raises ArgumentError do
        Couchbase.new(url)
      end
    end
  end

  def test_it_able_to_connect_to_protected_buckets
    skip
    with_configs(:buckets_spec => 'protected:secret') do |configs|
      connection = Couchbase.new(:hostname => configs.host,
                                 :port => configs.port,
                                 :bucket => 'protected',
                                 :username => 'protected',
                                 :password => 'secret')
      assert_equal "protected", connection.bucket
      assert_equal "protected", connection.username
      assert_equal "secret", connection.password
      connection.disconnect
    end
  end

  def test_it_allows_to_specify_credentials_in_url
    skip
    with_configs(:buckets_spec => 'protected:secret') do |configs|
      connection = Couchbase.new("http://protected:secret@#{configs.host}:#{configs.port}/pools/default/buckets/protected/")
      assert_equal "protected", connection.bucket
      assert_equal "protected", connection.username
      assert_equal "secret", connection.password
      connection.disconnect
    end
  end

  def test_it_raises_error_with_wrong_credentials
    with_configs do |configs|
      assert_raises Couchbase::Error::Auth do
        Couchbase.new(:hostname => configs.host,
                      :port => configs.port,
                      :bucket => 'default',
                      :username => 'wrong.username',
                      :password => 'wrong_password')
      end
    end
  end

  def test_it_unable_to_connect_to_protected_buckets_with_wrong_credentials
    skip
    with_configs(:buckets_spec => 'protected:secret') do |configs|
      assert_raises Couchbase::Error::Auth do
        Couchbase.new(:hostname => configs.host,
                      :port => configs.port,
                      :bucket => 'protected',
                      :username => 'wrong',
                      :password => 'secret')
      end
      assert_raises Couchbase::Error::Auth do
        Couchbase.new(:hostname => configs.host,
                      :port => configs.port,
                      :bucket => 'protected',
                      :username => 'protected',
                      :password => 'wrong')
      end
    end
  end

  def test_it_allows_change_quiet_flag
    with_configs do |configs|
      connection = Couchbase.new(:hostname => configs.host,
                                 :port => configs.port)

      refute connection.quiet?

      connection.disconnect
      connection = Couchbase.new(:hostname => configs.host,
                                 :port => configs.port,
                                 :quiet => true)
      assert connection.quiet?

      connection.quiet = nil
      assert_equal false, connection.quiet?

      connection.quiet = :foo
      assert_equal true, connection.quiet?
      connection.disconnect
    end
  end

  def test_it_is_connected
    with_configs do |configs|
      connection = Couchbase.new(:hostname => configs.host,
                                 :port => configs.port)
      assert connection.connected?
      connection.disconnect
    end
  end

  def test_it_is_possible_to_disconnect_instance
    with_configs do |configs|
      connection = Couchbase.new(:hostname => configs.host,
                                 :port => configs.port)
      connection.disconnect
      refute connection.connected?
    end
  end

  def test_it_raises_error_on_double_disconnect
    with_configs do |configs|
      connection = Couchbase.new(:hostname => configs.host,
                                 :port => configs.port)
      connection.disconnect
      assert_raises Couchbase::Error::Connect do
        connection.disconnect
      end
    end
  end

  def test_it_allows_to_reconnect_the_instance
    with_configs do |configs|
      connection = Couchbase.new(:hostname => configs.host,
                                 :port => configs.port)
      connection.disconnect
      refute connection.connected?
      connection.reconnect
      assert connection.connected?
      assert connection.set(uniq_id, "foo")
      connection.disconnect
    end
  end

  def test_it_allows_to_change_configuration_during_reconnect
    skip
    with_configs do |configs|
      connection = Couchbase.new(:quiet => true)
      assert connection.quiet?
      connection.disconnect

      connection.reconnect(:quiet => false)
      refute connection.quiet?
      connection.disconnect
    end
  end

  def test_it_uses_bucket_name_as_username_if_username_is_empty
    skip
    with_configs(:buckets_spec => 'protected:secret') do |configs|
      connection = Couchbase.new(:hostname => configs.host,
                                 :port => configs.port,
                                 :bucket => 'protected',
                                 :password => 'secret')
      assert connection.connected?
      connection.disconnect
    end
  end

  def test_it_converts_options_keys_to_symbols
    bucket = Couchbase::Bucket.new('quiet' => true, 'default_ttl' => 10)
    assert bucket.quiet?
    assert_equal 10, bucket.default_ttl
    bucket.disconnect
  end

  def test_can_flush_bucket
    assert cb.flush
  end

end
