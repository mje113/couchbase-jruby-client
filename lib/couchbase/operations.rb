module Couchbase
  module Operations
    java_import com.couchbase.client.java.PersistTo

    TRANSCODERS = {
      plain: Transcoders::PlainTranscoder.new,
      json:  Transcoders::MultiJsonTranscoder.new,
      doc:   Transcoders::JsonDocumentTranscoder.new
    }

    PERSIST_TO = {
      :master => PersistTo::MASTER,
      0 => PersistTo::NONE,
      1 => PersistTo::ONE,
      2 => PersistTo::TWO,
      3 => PersistTo::THREE,
      4 => PersistTo::FOUR
    }

    def set(id, value, options = {})
      if options[:persist_to]
        upsert_with_persistance(id, value, options)
      else
        upsert(id, value, options)
      end
    end

    def upsert(id, value, options = {})
      doc = to_doc(id, value, options)
      @bucket.upsert(doc)
    end

    def upsert_with_persistance(id, value, options = {})
      doc = to_doc(id, value, options)
      @bucket.upsert(doc, PERSIST_TO[options[:persist_to]])
    end

    def add(id, value, options = {})
      insert(id, value, options)
    end

    def insert(id, value, options = {})
      doc = to_doc(id, value, options)
      @bucket.insert(doc)
    end

    def get(id, options = {})
      doc = @bucket.get(id, transcoder(options).java_document_class.java_class)
      return nil if doc.nil?

      from_doc(doc, options)
    end

    def remove(id)
      @bucket.remove(id)
    end

    private

    def transcoder(options)
      TRANSCODERS[options[:format] || :json]
    end

    def to_doc(id, value, options)
      transcoder(options).to_doc(id, value, options)
    end

    def from_doc(doc, options)
      transcoder(options).from_doc(doc)
    end
  end
end
