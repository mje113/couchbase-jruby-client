require 'helper'

class TestConfiguration < Minitest::Test

  def test_default
    config = Couchbase::Configuration.new
    assert_equal 'localhost', config[:hostname]
    assert_equal 'default',   config[:bucket]
  end

  def test_override_default
    config = Couchbase::Configuration.new(hostname: '127.0.0.1', bucket: 'cats')
    assert_equal '127.0.0.1', config[:hostname]
    assert_equal 'cats',      config[:bucket]
  end
end
