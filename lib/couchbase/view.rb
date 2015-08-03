module Couchbase
  class View
    java_import com.couchbase.client.java.view.ViewQuery
    java_import com.couchbase.client.java.document.json.JsonArray
    java_import com.couchbase.client.java.document.RawJsonDocument

    def initialize(design_doc, view, bucket)
      @format = :json
      @bucket = bucket.bucket
      @view_query = ViewQuery.from(design_doc, view.to_s)
    end

    def key(key)
      case key
      when Array
        @view_query.key(JsonArray.from(key.to_java))
      else
        @view_query.key(key)
      end
      self
    end

    def limit(num)
      @view_query.limit(num)
      self
    end

    def fresh
      @view_query.stale(com.couchbase.client.java.view.Stale::FALSE)
      self
    end

    def format(format)
      raise ArgumentError unless Operations::TRANSCODERS.keys.include?(format)
      @format = format
      self
    end

    def fetch
      results = @bucket.query(@view_query)
      {}.tap do |response|
        results.each do |view_row|
          doc = view_row.document(Operations::TRANSCODERS[@format].java_document_class.java_class)
          response[view_row.id] = doc.nil? ? nil : Operations::TRANSCODERS[@format].from_doc(doc)
        end
      end
    end
  end
end
