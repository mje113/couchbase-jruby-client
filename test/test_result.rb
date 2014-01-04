require File.join(File.dirname(__FILE__), 'setup')

class TestResult < Minitest::Test

  def test_result_object_provides_enough_info
    obj = Couchbase::Result.new
    assert obj.respond_to?(:success?)
    assert obj.respond_to?(:error)
    assert obj.respond_to?(:key)
    assert obj.respond_to?(:value)
    assert obj.respond_to?(:node)
    assert obj.respond_to?(:cas)
  end

end
