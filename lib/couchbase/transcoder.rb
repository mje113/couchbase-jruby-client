module Couchbase

  class Transcoder

    def create_with_ttl(key, value, options)
      if options[:ttl]
        java_document_class.create(key, options[:ttl], value)
      else
        java_document_class.create(key, value)
      end
    end

    def java_document_class
      fail NotImplementedError
    end

    def to_doc(*)
      fail NotImplementedError
    end

    def from_doc(*)
      fail NotImplementedError
    end

    def decode(*)
      fail NotImplementedError
    end

    def encode(*)
      fail NotImplementedError
    end
  end
end
