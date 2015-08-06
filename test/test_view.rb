require 'helper'

class TestView < Minitest::Test

  def setup
    @bucket = Couchbase.bucket
    @design_doc = {
      test_view: {
        map: <<-JS
          function(doc, meta) {
            emit(meta.id);
          }
        JS
      }
    }
    @bucket.save_design_doc('test', @design_doc)
  end

  def test_view_query
    @bucket.upsert(uniq_id, true)
    results = @bucket.query('test', 'test_view')
      .fresh
      .fetch
    assert_equal true, results[uniq_id].to_h
  end

  def test_returns_nils_as_appropriate
    100.times { |i| @bucket.upsert(uniq_id(i), true) }
    # Force an index
    @bucket.query('test', 'test_view').fresh.fetch
    100.times { |i| @bucket.remove(uniq_id(i)) }
    results = @bucket.query('test', 'test_view').fetch
    assert_nil results[uniq_id(23)]
  end
end
