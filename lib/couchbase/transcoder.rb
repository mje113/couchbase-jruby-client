module Couchbase

  class Transcoder

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
