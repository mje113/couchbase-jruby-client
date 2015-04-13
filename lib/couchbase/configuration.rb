module Couchbase

  class Configuration

    DEFAULT_CONFIG = {
      host:     'localhost',
      bucket:   'default',
      password: ''
    }

    Bucket = Struct.new(:name, :password)

    attr_accessor :hosts, :buckets

    def initialize(config = {})
      config = DEFAULT_CONFIG.merge(symbolize_keys(config))
      @hosts = Array(config[:hosts] || config[:host] || config[:hostname])

      if config[:buckets]
        @buckets = config[:buckets].map { |b|
          Bucket.new(b[:name], b[:password])
        }
      else
        @buckets = [ Bucket.new(config[:bucket], config[:password]) ]
      end
    end

    private

    def symbolize_keys(old_hash)
      {}.tap do |hash|
        old_hash.each_pair do |key, value|
          hash[key.to_sym] = value
        end
      end
    end
  end
end
