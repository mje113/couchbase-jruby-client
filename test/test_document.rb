require 'helper'

class TestDocument < Minitest::Test
  include Couchbase

  java_import com.couchbase.client.java.document.RawJsonDocument

  def setup
    @json_string = '{"a":1,"b":2,"c":3}'
    @json_hash = MultiJson.load(@json_string)
    @document = Document.new(RawJsonDocument.create('doc', 100, @json_string))
  end

  def test_java_doc_conversion
    assert_equal 'doc', @document.id
    assert_equal 0,     @document.cas
    assert_equal 100,   @document.ttl
    assert_equal @json_string, @document.content
    assert_equal @json_string, @document.to_s
    assert_equal @json_string, "#{@document}"
  end

  def test_hash_conversion
    assert_equal @json_hash, @document.to_h
  end

  def test_array_conversion
    assert_equal @json_hash, @document.to_a
  end

  def test_implicit_hash_conversion
    assert_equal 1, @document['a']
    assert_equal 2, @document['b']
    assert_equal 3, @document['c']
  end

  def test_each
    @document.each do |pair|
      assert_instance_of Array, pair
      assert_instance_of String, pair[0]
      assert_instance_of Fixnum, pair[1]
    end
  end

  def test_each_pair
    @document.each_pair do |k, v|
      assert_instance_of String, k
      assert_instance_of Fixnum, v
    end
  end
end
