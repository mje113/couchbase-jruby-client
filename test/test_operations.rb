require 'helper'

class TestOperations < Minitest::Test

  def test_set_and_get
    assert Couchbase.bucket.set(uniq_id, { a: 1 })
    assert_equal({ 'a' => 1 }, Couchbase.bucket.get(uniq_id))
  end

  def test_set_and_get_plain
    assert Couchbase.bucket.set(uniq_id, { a: 1 })
    assert_equal '{"a":1}', Couchbase.bucket.get(uniq_id, format: :plain)
  end

  def test_set_with_string_and_get_plain
    assert Couchbase.bucket.set(uniq_id, '{"a":1}')
    assert_equal '{"a":1}', Couchbase.bucket.get(uniq_id, format: :plain)
  end
end
