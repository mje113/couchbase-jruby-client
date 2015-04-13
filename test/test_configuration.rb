require 'helper'

class TestConfiguration < Minitest::Test

  def setup
    @single_config = {
      host: '127.0.0.1',
      bucket: 'fu',
      password: 'abc123'
    }

    @multiple_hosts = {
      hosts: [ 'host1', 'host2' ],
      bucket:   'bar',
      password: 'abc123'
    }

    @multple_buckets = {
      host: '127.0.0.1',
      buckets: [
        { name: 'fu',  password: 'abc123' },
        { name: 'bar', password: 'abc123' }
      ]
    }
  end

  def test_default
    config = Couchbase::Configuration.new
    assert_equal [ 'localhost' ], config.hosts
    assert_equal 'default', config.buckets.first.name
  end

  def test_single_config
    config = Couchbase::Configuration.new(@single_config)
    assert_equal [ '127.0.0.1' ], config.hosts
    assert_equal 'fu', config.buckets.first.name
    assert_equal 'abc123', config.buckets.first.password
  end

  def test_multiple_hosts
    config = Couchbase::Configuration.new(@multiple_hosts)
    assert_equal [ 'host1', 'host2' ], config.hosts
    assert_equal 'bar', config.buckets[0].name
    assert_equal 'abc123', config.buckets[0].password
  end

  def test_multiple_buckets
    config = Couchbase::Configuration.new(@multple_buckets)
    assert_equal [ '127.0.0.1' ], config.hosts
    assert_equal 'fu', config.buckets[0].name
    assert_equal 'bar', config.buckets[1].name
  end
end
