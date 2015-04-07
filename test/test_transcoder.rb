require 'helper'

class TestTranscoder < Minitest::Test

  def setup
    @transcoder = Couchbase::Transcoder.new
  end

  def test_decode_not_implemented
    assert_raises NotImplementedError do
      @transcoder.decode('')
    end
  end

  def test_encode_not_implemented
    assert_raises NotImplementedError do
      @transcoder.encode('')
    end
  end
end
