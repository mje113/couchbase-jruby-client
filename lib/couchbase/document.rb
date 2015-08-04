require 'forwardable'

module Couchbase
  class Document
    extend Forwardable

    attr_reader :id, :cas, :ttl, :content

    def initialize(java_doc)
      @id      = java_doc.id
      @cas     = java_doc.cas
      @ttl     = java_doc.expiry
      @content = java_doc.content
      @hash    = nil
    end

    def to_s
      @content
    end

    def to_h
      @hash ||= begin
                  MultiJson.load(@content)
                rescue MultiJson::ParseError
                  # TODO: figure out what to do here...
                end
    end

    def_delegators :to_h, :[], :each, :each_pair, :keys, :values, :key?
  end
end
