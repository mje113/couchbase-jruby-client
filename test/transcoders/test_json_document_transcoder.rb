require 'helper'

class TestJsonDocumentTranscoder < Minitest::Test

  java_import com.couchbase.client.java.document.JsonDocument

  def setup
    @doc = JsonDocument.create('key')
    @transcoder = Couchbase::Transcoders::JsonDocumentTranscoder.new
  end

  def test_from_doc
    assert_equal @doc, @transcoder.from_doc(@doc)
  end

  def test_to_doc
    skip
  end

  def test_java_document_class
    assert_equal JsonDocument.java_class, @transcoder.java_document_class.java_class
  end
end
