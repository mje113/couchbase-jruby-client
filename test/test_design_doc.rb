require 'helper'

class TestDesignDoc < Minitest::Test

  def test_create_design_doc
    dd = {
      by_foo: {
        map: <<-JS
          function(doc, meta) {
            emit(doc.id, null)
          }
        JS
      }
    }

    design_doc = Couchbase::DesignDoc.new('bar', dd)
    assert_instance_of com.couchbase.client.java.view.DesignDocument,
                       design_doc.create
  end

  def test_incorrect_doc_format
    dd = {
      by_fu: ''
    }
    assert_raises Couchbase::DesignDocFormatError do
      Couchbase::DesignDoc.new('bar', dd)
    end
  end
end
