require 'helper'

class TestMultiJsonTranscoder < Minitest::Test

  java_import com.couchbase.client.java.document.RawJsonDocument

  def setup
    @json = { 'a' => 'a', 'b' => { 'c' => 1, 'd' => 2 }, 'e' => [1, 2, 3] }
    @transcoder = Couchbase::Transcoders::MultiJsonTranscoder.new
  end

  def test_from_doc
    doc = RawJsonDocument.create('key', MultiJson.dump(@json))
    assert_equal @json, @transcoder.from_doc(doc)
  end

  def test_to_doc
    doc = @transcoder.to_doc('key', @json)
    assert_equal MultiJson.dump(@json), doc.content
    assert_equal 'key', doc.id
  end

  def test_java_document_class
    assert_equal RawJsonDocument.java_class, @transcoder.java_document_class.java_class
  end
end
