require 'delegate'

module Couchbase
  class Document < DelegateClass(Hash)

    attr_reader :id, :cas, :ttl, :content

    def initialize(java_doc)
      @id      = java_doc.id
      @cas     = java_doc.cas
      @ttl     = java_doc.expiry
      @content = java_doc.content
    end
  end
end
