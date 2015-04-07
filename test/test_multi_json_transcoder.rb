require 'helper'

class TestMultiJsonTranscoder < Minitest::Test

  def setup
    @transcoder = Couchbase::Transcoders::MultiJson.new
  end

  def test_java_doc_class
    assert_equal com.couchbase.client.java.document.RawJsonDocument,
                 @transcoder.java_document_class
  end

  def test_decode
    assert_equal({ 'a' => 1, 'b' => 'c' }, @transcoder.decode('{"a":1,"b":"c"}'))
  end

  def test_encode
    assert_equal '{"a":1,"b":"c"}', @transcoder.encode({ 'a' => 1, 'b' => 'c' })
  end
end
