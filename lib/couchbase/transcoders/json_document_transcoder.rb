module Couchbase
  module Transcoders

    class JsonDocumentTranscoder < Couchbase::Transcoder

      java_import com.couchbase.client.java.document.JsonDocument

    end
  end
end
