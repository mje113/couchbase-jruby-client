require 'helper'

class TestCouchbase < Minitest::Test

  def test_couchbase_module
    assert Couchbase.is_a? Module
  end
end
