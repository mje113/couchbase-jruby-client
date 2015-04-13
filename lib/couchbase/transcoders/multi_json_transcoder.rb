require 'multi_json'

module Couchbase
  module Transcoders

    class MultiJsonTranscoder < Couchbase::Transcoder

      java_import com.couchbase.client.java.document.RawJsonDocument

      JAVA_DOCUMENT_CLASS = RawJsonDocument

      def java_document_class
        JAVA_DOCUMENT_CLASS
      end

      def to_doc(key, value)
        value = encode(value) if value.is_a?(Hash)
        java_document_class.create(key, value)
      end

      def from_doc(doc, options = {})
        if options[:format] == :plain
          doc.content
        else
          decode(doc.content)
        end
      end

      private

      def decode(data)
        MultiJson.load(data)
      rescue MultiJson::ParseError
        data
      end

      def encode(object)
        MultiJson.dump(object)
      end
    end
  end
end
