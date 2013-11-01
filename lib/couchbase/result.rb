module Couchbase
  class Result

    attr_accessor :error

    def initialize(attrs = {})
      @bucket    = attrs[:bucket]
      @key       = attrs[:key]
      @operation = attrs[:op]
      @future    = attrs[:future]
    end

    def operation
      @operation
    end

    def success?
      @future.get
    end

    def error
      @error
    end

    def key
      @key || @future.getKey
    end

    def value
      @future.get
    rescue MultiJson::LoadError
      nil
    end

    def cas
      @future.getCas if @future.respond_to?(:getCas)
    end

    def node

    end
  end
end
