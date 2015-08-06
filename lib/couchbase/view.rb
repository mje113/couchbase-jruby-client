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
      @view_query.key(convert_key(key))
      self
    end

    def keys(keys)
      @view_query.keys(JsonArray.from(keys.to_java))
      self
    end

    def start_key(key)
      @view_query.start_key(convert_key(key))
      self
    end

    def end_key(key)
      @view_query.end_key(convert_key(key))
      self
    end

    def limit(num)
      @view_query.limit(num)
      self
    end

    def skip(num)
      @view_query.skip(num)
      self
    end

    def group(group = true)
      @view_query.group(group)
      self
    end

    def group_level(level)
      @view_query.group_level(level)
      self
    end

    def reduce(reduce = true)
      @view_query.reduce(reduce)
      self
    end

    def fresh
      @view_query.stale(com.couchbase.client.java.view.Stale::FALSE)
      self
    end

    def fetch
      results = @bucket.query(@view_query)
      {}.tap do |response|
        results.each do |view_row|
          doc = view_row.document(RawJsonDocument.java_class)
          response[view_row.id] = doc.nil? ? nil : Document.new(doc)
        end
      end
    end

    private

    def convert_key(key)
      case key
      when Array
        @view_query.key(JsonArray.from(key.to_java))
      else
        @view_query.key(key)
      end
    end
  end
end
