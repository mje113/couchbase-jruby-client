require 'helper'

class TestOperations < Minitest::Test

  def setup
    @bucket = Couchbase.bucket(:default)
  end

  def test_set_and_get
    assert @bucket.set(uniq_id, a: 1)
    assert_equal({ 'a' => 1 }, @bucket.get(uniq_id).to_h)
  end

  def test_set_and_remove
    assert @bucket.set(uniq_id, a: 1)
    assert @bucket.remove(uniq_id)
  end

  def test_add_and_get
    assert @bucket.add(uniq_id, a: 1)
    assert_equal({ 'a' => 1 }, @bucket.get(uniq_id).to_h)
  end

  def test_set_and_get_plain
    assert @bucket.set(uniq_id, a: 1)
    assert_equal '{"a":1}', @bucket.get(uniq_id).to_s
  end

  def test_set_with_string_and_get_plain
    assert @bucket.set(uniq_id, '{"a":1}')
    assert_equal '{"a":1}', @bucket.get(uniq_id).to_s
  end

  def test_set_with_string_and_get
    assert @bucket.set(uniq_id, '{"a":1}')
    assert_equal({ 'a' => 1 }, @bucket.get(uniq_id).to_h)
  end

  def test_set_with_ttl
    assert @bucket.set(uniq_id, { a: 1 }, ttl: 1)
    refute_nil @bucket.get(uniq_id)
    sleep 2
    assert_nil @bucket.get(uniq_id)
  end

  def test_set_with_persist_to
    assert @bucket.set(uniq_id, { a: 1 }, persist_to: :master)
  end
end
