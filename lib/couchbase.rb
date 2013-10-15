
unless RUBY_PLATFORM =~ /java/
  error "This gem is only compatible with a java-based ruby environment like JRuby."
  exit 255
end

require 'java'
require 'jars/commons-codec-1.5.jar'
require 'jars/couchbase-client-1.2.0.jar'
require 'jars/jettison-1.1.jar'
require 'jars/httpcore-4.1.1.jar'
require 'jars/netty-3.5.5.Final.jar'
require 'jars/spymemcached-2.10.0.jar'
require 'jars/httpcore-nio-4.1.1.jar'
require 'couchbase/version'
require 'uri'
require 'atomic'
require 'couchbase/transcoder'
require 'couchbase/async'
require 'couchbase/operations'
require 'couchbase/error'
require 'couchbase/constants'
require 'couchbase/utils'
require 'couchbase/bucket'
require 'couchbase/view_row'
require 'couchbase/view'
require 'couchbase/result'
require 'couchbase/cluster'

include Java

import Java::com.couchbase.client.CouchbaseClient;

at_exit do
  Couchbase.disconnect
end

# Couchbase jruby client
module Couchbase

  @@bucket = Atomic.new(nil)

  class << self

    # The method +connect+ initializes new Bucket instance with all arguments passed.
    #
    # @since 1.0.0
    #
    # @see Bucket#initialize
    #
    # @example Use default values for all options
    #   Couchbase.connect
    #
    # @example Establish connection with couchbase default pool and default bucket
    #   Couchbase.connect("http://localhost:8091/pools/default")
    #
    # @example Select custom bucket
    #   Couchbase.connect("http://localhost:8091/pools/default", :bucket => 'blog')
    #
    # @example Specify bucket credentials
    #   Couchbase.connect("http://localhost:8091/pools/default", :bucket => 'blog', :username => 'bucket', :password => 'secret')
    #
    # @example Use URL notation
    #   Couchbase.connect("http://bucket:secret@localhost:8091/pools/default/buckets/blog")
    #
    # @return [Bucket] connection instance
    def connect(*options)
      disconnect
      @@bucket.update { |bucket| bucket ||= Bucket.new(*(options.flatten)) }
      @@bucket.value
    end
    alias :new :connect

    # Default connection options
    #
    # @since 1.1.0
    #
    # @example Using {Couchbase#connection_options} to change the bucket
    #   Couchbase.connection_options = {:bucket => 'blog'}
    #   Couchbase.bucket.name     #=> "blog"
    #
    # @return [Hash, String]
    attr_accessor :connection_options

    # The connection instance for current thread
    #
    # @since 1.1.0
    #
    # @see Couchbase.connection_options
    #
    # @example
    #   Couchbase.bucket.set("foo", "bar")
    #
    # @return [Bucket]
    def bucket
      if !connected?
        connect(connection_options)
      end
      @@bucket.value
    end

    # Set a connection instance for current thread
    #
    # @since 1.1.0
    #
    # @return [Bucket]
    def bucket=(connection)
      @@bucket.update { |bucket| bucket = connection }
    end

    def connected?
      !!@@bucket.value
    end

    def disconnect
      @@bucket.value.disconnect if connected?
      @@bucket = Atomic.new(nil)
    end
  end
end

__END__

    def self.connect(*options)
      disconnect
      Bucket.new(*(options.flatten))
    end

    def self.new(*options)
      connect(options)
    end

    # Default connection options
    #
    # @since 1.1.0
    #
    # @example Using {Couchbase#connection_options} to change the bucket
    #   Couchbase.connection_options = {:bucket => 'blog'}
    #   Couchbase.bucket.name     #=> "blog"
    #
    # @return [Hash, String]
    attr_accessor :connection_options

    # The connection instance for current thread
    #
    # @since 1.1.0
    #
    # @see Couchbase.connection_options
    #
    # @example
    #   Couchbase.bucket.set("foo", "bar")
    #
    # @return [Bucket]
    def self.bucket
      @bucket ||= connect(connection_options)
    end

    # Set a connection instance for current thread
    #
    # @since 1.1.0
    #
    # @return [Bucket]
    def self.bucket=(connection)
      @bucket = connection
    end

    def self.connected?
      !!@bucket
    end

    def self.disconnect
      bucket.disconnect if connected?
      @bucket = nil
    end

end

