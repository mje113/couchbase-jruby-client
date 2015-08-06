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
      @data    = nil
    end

    def to_s
      @content
    end

    def data
      @data ||= begin
                  MultiJson.load(@content)
                rescue MultiJson::ParseError
                  # TODO: figure out what to do here...
                end
    end
    alias_method :to_a, :data
    alias_method :to_h, :data

    def_delegators :data, :[], :each, :each_pair, :keys, :values, :key?
  end
end
