require 'helper'

class TestDocument < Minitest::Test
  include Couchbase

  java_import com.couchbase.client.java.document.RawJsonDocument
  java_import com.couchbase.client.java.document.JsonDocument

  def setup
    @doc = RawJsonDocument.create('doc', 100, '{"a":1,"b":"c"}')
  end

  def test_java_doc_conversion
    document = Document.new(@doc)
    assert_equal 'doc', document.id
    assert_equal 0,     document.cas
    assert_equal 100,   document.ttl
  end
end
