module Couchbase
  module Transcoders

    class PlainTranscoder < Couchbase::Transcoder

      java_import com.couchbase.client.java.document.RawJsonDocument

      def java_document_class
        RawJsonDocument
      end

      def to_doc(key, value, options = {})
        raise ArgumentError, 'Value must respond to to_str' unless value.respond_to?(:to_str)
        create_with_ttl(key, value.to_str, options)
      end

      def from_doc(doc)
        doc.content
      end
    end
  end
end
