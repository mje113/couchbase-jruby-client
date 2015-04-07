module Couchbase
  module Operations

    java_import java.util.concurrent.TimeUnit

    def set(key, value, options = {})
      doc = @transcoder.to_doc(key, value)

      if options[:ttl]
        @bucket.upsert(doc, options[:ttl], TimeUnit::SECONDS)
      else
        @bucket.upsert(doc)
      end
    end

    def get(key, options = {})
      doc = @bucket.get(key, @transcoder.java_document_class.java_class)
      return nil if doc.nil?

      @transcoder.from_doc(doc, options)
    end
  end
end
