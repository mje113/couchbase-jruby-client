module Couchbase

  class Transcoder

    def java_document_class
      fail NotImplementedError
    end

    def to_doc(key, value)
      fail NotImplementedError
    end

    def from_doc(doc, options = {})
      fail NotImplementedError
    end

    def decode(d)
      fail NotImplementedError
    end

    def encode(o)
      fail NotImplementedError
    end
  end
end
