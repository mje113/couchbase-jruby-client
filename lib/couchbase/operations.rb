module Couchbase
  module Operations
    java_import com.couchbase.client.java.PersistTo

    TRANSCODERS = {
      plain: Transcoders::PlainTranscoder.new,
      json:  Transcoders::MultiJsonTranscoder.new,
      doc:   Transcoders::JsonDocumentTranscoder.new
    }

    PERSIST_TO = {
      0 => PersistTo::NONE,
      1 => PersistTo::ONE,
      2 => PersistTo::TWO,
      3 => PersistTo::THREE,
      4 => PersistTo::FOUR
    }

    def set(key, value, options = {})
      doc = to_doc(key, value, options)
      if options[:persist_to]
        @bucket.upsert(doc, PERSIST_TO[options[:persist_to]])
      else
        @bucket.upsert(doc)
      end
    end

    def get(key, options = {})
      doc = @bucket.get(key, transcoder(options).java_document_class.java_class)
      return nil if doc.nil?

      from_doc(doc, options)
    end

    private

    def transcoder(options)
      TRANSCODERS[options[:format] || :json]
    end

    def to_doc(key, value, options)
      transcoder(options).to_doc(key, value, options)
    end

    def from_doc(doc, options)
      transcoder(options).from_doc(doc)
    end
  end
end
