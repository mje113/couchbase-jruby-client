require 'multi_json'

module Couchbase
  module Transcoders

    class MultiJsonTranscoder < Couchbase::Transcoder

      java_import com.couchbase.client.java.document.RawJsonDocument

      def java_document_class
        RawJsonDocument
      end

      def to_doc(key, value, options = {})
        create_with_ttl(key, encode(value), options)
      end

      def from_doc(doc)
        decode(doc.content)
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
