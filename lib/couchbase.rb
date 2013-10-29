
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

  @@buckets = Atomic.new({})

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
      Bucket.new(*(options.flatten))
      # disconnect
      # @@bucket.update { |bucket| bucket ||= Bucket.new(*(options.flatten)) }
      # @@bucket.value
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
    # @example Set connection options using Hash
    #   Couchbase.connection_options = {:node_list => ["example.com:8091"]}
    #   Couchbase.bucket("slot1").set("foo", "bar")
    #   Couchbase.bucket("slot1").bucket #=> "default"
    #   Couchbase.connection_options[:bucket] = "test"
    #   Couchbase.bucket("slot2").bucket #=> "test"
    #
    # @example Set connection options using URI
    #   Couchbase.connection_options = "http://example.com:8091/pools"
    #   Couchbase.bucket("slot1").set("foo", "bar")
    #   Couchbase.bucket("slot1").bucket #=> "default"
    #   Couchbase.connection_options = "http://example.com:8091/pools/buckets/test"
    #   Couchbase.bucket("slot2").bucket #=> "test"
    #
    # @example Use named slots to keep a connection
    #   Couchbase.connection_options = {
    #     :node_list => ["example.com", "example.org"],
    #     :bucket => "users"
    #   }
    #   Couchbase.bucket("users").set("john", {"balance" => 0})
    #   Couchbase.connection_options[:bucket] = "orders"
    #   Couchbase.bucket("other").set("john:1", {"products" => [42, 66]})
    #
    # @return [Bucket]
    def bucket(name = nil)
      name ||= case @connection_options
               when Hash
                 @connection_options[:bucket]
               when String
                 path = URI.parse(@connection_options).path
                 path[%r(^(/pools/([A-Za-z0-9_.-]+)(/buckets/([A-Za-z0-9_.-]+))?)?), 3] || "default"
               else
                 "default"
               end
      @@buckets.update { |buckets| buckets[name] ||= connect(connection_options) }
      @@buckets.value[name]
    end

    # Set a connection instance for current thread
    #
    # @since 1.1.0
    #
    # @return [Bucket]
    def bucket=(connection)
      name ||= @connection_options && @connection_options[:bucket] || "default"
      @@buckets.update { |buckets| buckets[name] = connection }
      @@buckets.value[name]
    end

    def connected?
      !!@@buckets.value.empty?
    end

    def disconnect
      @@buckets.value.each(&:disconnect) if connected?
      @@buckets = Atomic.new({})
    end
  end
end

