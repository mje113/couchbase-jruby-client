require 'helper'

class TestBucket < Minitest::Test

  def setup
    @bucket = Couchbase.bucket(:default)
  end

  def test_async_access
    assert_instance_of com.couchbase.client.java.CouchbaseAsyncBucket,
                       @bucket.async
  end

  def test_legacy_set_and_get
    obj = { 'a' => 1, 'b' => 'b', 'c' => true, 'd' => [1, 2, 3] }
    assert @bucket.set('a', obj)
    doc = @bucket.get('a')
    assert_equal obj, doc.to_h
  end

  def test_get_and_set_string
    assert @bucket.set('a', 'a')
    assert_equal 'a', @bucket.get('a').to_s
  end

  def test_flush_bucket
    assert @bucket.flush
  end
end
