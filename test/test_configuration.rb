require 'helper'

class TestConfiguration < Minitest::Test

  SINGLE_CONFIG = {
    host: '127.0.0.1',
    bucket: 'fu',
    password: 'abc123'
  }

  MULTIPLE_HOSTS = {
    hosts: %w(host1 host2),
    bucket: 'bar',
    password: 'abc123'
  }

  MULTIPLE_BUCKETS = {
    host: '127.0.0.1',
    buckets: [
      { 'name' => 'fu',  'password' => 'abc123' },
      { 'name' => 'bar', 'password' => 'abc123' }
    ]
  }

  def test_default
    config = Couchbase::Configuration.new
    assert_equal ['localhost'], config.hosts
    assert_equal 'default', config.buckets.first.name
  end

  def test_single_config
    config = Couchbase::Configuration.new(SINGLE_CONFIG)
    assert_equal ['127.0.0.1'], config.hosts
    assert_equal 'fu', config.buckets.first.name
    assert_equal 'abc123', config.buckets.first.password
  end

  def test_multiple_hosts
    config = Couchbase::Configuration.new(MULTIPLE_HOSTS)
    assert_equal %w(host1 host2), config.hosts
    assert_equal 'bar', config.buckets[0].name
    assert_equal 'abc123', config.buckets[0].password
  end

  def test_multiple_buckets
    config = Couchbase::Configuration.new(MULTIPLE_BUCKETS)
    assert_equal ['127.0.0.1'], config.hosts
    assert_equal 'fu', config.buckets[0].name
    assert_equal 'bar', config.buckets[1].name
  end
end
