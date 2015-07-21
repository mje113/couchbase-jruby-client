require 'helper'

class TestPlainTranscoder < Minitest::Test
  java_import com.couchbase.client.java.document.RawJsonDocument

  def setup
    @string = 'fubar'
    @transcoder = Couchbase::Transcoders::PlainTranscoder.new
  end

  def test_from_string
    doc = RawJsonDocument.create('key', @string)
    assert_equal @string, @transcoder.from_doc(doc)
  end

  def test_to_doc
    doc = @transcoder.to_doc('key', @string)
    assert_equal @string, doc.content
    assert_equal 'key', doc.id
  end

  def test_raises_exception_if_value_is_not_a_string
    assert_raises ArgumentError do
      @transcoder.to_doc('key', 123)
    end
  end

  def test_java_document_class
    assert_equal RawJsonDocument.java_class, @transcoder.java_document_class.java_class
  end
end
