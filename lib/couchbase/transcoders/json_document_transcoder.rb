module Couchbase
  module Transcoders

    class JsonDocumentTranscoder < Couchbase::Transcoder

      java_import com.couchbase.client.java.document.JsonDocument

      def java_document_class
        JsonDocument
      end

      def from_doc(doc)
        doc
      end
    end
  end
end
