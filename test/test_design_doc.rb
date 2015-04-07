require 'helper'

class TestDesignDoc < Minitest::Test

  def test_create_design_doc
    dd = {
      by_something: {
        map: <<-JS
          function(doc, meta) {
            emit(doc.id, null)
          }
        JS
      }
    }

    design_doc = Couchbase::DesignDoc.new('name', dd)
    assert_instance_of com.couchbase.client.java.view.DesignDocument,
                       design_doc.create
  end
end
