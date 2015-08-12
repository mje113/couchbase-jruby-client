require 'helper'

class TestView < Minitest::Test

  def setup
    @bucket = Couchbase.bucket(:default)
    @design_doc = {
      test_map: {
        map: <<-JS
          function(doc, meta) {
            emit(meta.id);
          }
        JS
      },
      test_reduce: {
        map: 'function(doc, meta) { emit(meta.id, null); }',
        reduce: '_count'
      }
    }
    @bucket.save_design_doc('test', @design_doc)
  end

  def test_view_query
    @bucket.upsert(uniq_id, true)
    results = @bucket.query('test', 'test_map')
      .fresh
      .fetch

    assert_equal true, results[uniq_id].data
  end

  def test_key
    @bucket.upsert(uniq_id, true)
    results = @bucket.query('test', 'test_map')
      .key(uniq_id)
      .fresh
      .fetch

    assert_equal 1, results.size
    assert_equal true, results[uniq_id].data
  end

  def test_keys
    @bucket.upsert(uniq_id(:a), true)
    @bucket.upsert(uniq_id(:b), true)
    results = @bucket.query('test', 'test_map')
      .keys([uniq_id(:a), uniq_id(:b)])
      .fresh
      .fetch

    assert_equal 2, results.size
    assert_equal true, results[uniq_id(:a)].data
    assert_equal true, results[uniq_id(:b)].data
  end

  def test_returns_nils_as_appropriate
    100.times { |i| @bucket.upsert(uniq_id(i), true) }
    # Force an index
    @bucket.query('test', 'test_map').fresh.fetch
    100.times { |i| @bucket.remove(uniq_id(i)) }
    results = @bucket.query('test', 'test_map').fetch
    assert_nil results[uniq_id(23)]
  end

  def test_reduced_view
    @bucket.upsert(uniq_id, true)
    results = @bucket.query('test', 'test_reduce')
      .fresh
      .fetch

    assert_instance_of Fixnum, results
    assert results > 0
  end

  def test_non_reduced_view
    @bucket.upsert(uniq_id, true)
    results = @bucket.query('test', 'test_reduce')
      .fresh
      .reduce(false)
      .fetch

    assert_equal true, results[uniq_id].data
  end


end
