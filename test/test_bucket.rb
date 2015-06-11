require 'helper'

class TestBucket < Minitest::Test

  def test_async_access
    assert_instance_of com.couchbase.client.java.CouchbaseAsyncBucket,
                       Couchbase.bucket.async
  end

  def test_legacy_set_and_get
    obj = { 'a' => 1, 'b' => 'b', 'c' => true, 'd' => [1, 2, 3] }
    assert Couchbase.bucket.set('a', obj)
    doc = Couchbase.bucket.get('a')
    assert_equal obj, doc
  end

  def test_get_and_set_string
    assert Couchbase.bucket.set('a', 'a')
    assert_equal 'a', Couchbase.bucket.get('a')
  end

  def test_flush_bucket
    assert Couchbase.bucket.flush
  end
end
