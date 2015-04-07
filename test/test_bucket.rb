require 'helper'

class TestBucket < Minitest::Test

  def test_async_access
    assert_instance_of com.couchbase.client.java.CouchbaseAsyncBucket,
                       Couchbase.bucket.async
  end
end
