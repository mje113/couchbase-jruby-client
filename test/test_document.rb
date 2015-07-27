require 'helper'

class TestDocument < Minitest::Test

  java_import com.couchbase.client.java.document.RawJsonDocument
  java_import com.couchbase.client.java.document.JsonDocument

  def setup
    @doc = RawJsonDocument.create('doc', 100, '{"a":1,"b":"c"}')
  end

  def test_java_doc_conversion
    document = Couchbase::Document.new(@doc)
  end
end
