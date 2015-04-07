module Couchbase

  class Configuration

    DEFAULT_CONFIG = {
      hostname:   'localhost',
      bucket:     'default',
      password:   ''
    }

    def initialize(options = {})
      @config = DEFAULT_CONFIG.merge(symbolize_keys(options))
    end

    def [](key)
      @config[key]
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
