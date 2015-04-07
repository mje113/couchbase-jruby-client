module Couchbase

  class Transcoder

    def java_document_class
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
