module Couchbase
  module Operations
    java_import com.couchbase.client.java.PersistTo
    java_import com.couchbase.client.java.document.RawJsonDocument

    RAW_JSON_DOCUMENT_CLASS = RawJsonDocument.java_class

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
      doc = doc_with_ttl(id, value, options)
      @bucket.upsert(doc)
    end

    def upsert_with_persistance(id, value, options = {})
      doc = doc_with_ttl(id, value, options)
      @bucket.upsert(doc, PERSIST_TO[options[:persist_to]])
    end

    def add(id, value, options = {})
      insert(id, value, options)
    end

    def insert(id, value, options = {})
      doc = doc_with_ttl(id, value, options)
      @bucket.insert(doc)
    end

    def get(id, options = {})
      doc = @bucket.get(id, RAW_JSON_DOCUMENT_CLASS)
      return nil if doc.nil?
      Document.new(doc)
    end

    def remove(id)
      @bucket.remove(id)
    end

    private

    def doc_with_ttl(id, value, options)
      value = MultiJson.dump(value) unless value.respond_to?(:to_str)

      if options[:ttl]
        RawJsonDocument.create(id, options[:ttl], value)
      else
        RawJsonDocument.create(id, value)
      end
    end
  end
end
