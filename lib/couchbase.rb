# Author:: Mike Evans <mike@urlgonomics.com>
# Copyright:: 2013 Urlgonomics LLC.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

unless RUBY_PLATFORM =~ /java/
  fail "This gem is only compatible with a java-based ruby environment like JRuby."
  exit 255
end

require 'java'
require 'jars/commons-codec-1.5.jar'
require 'jars/couchbase-client-1.3.2.jar'
require 'jars/jettison-1.1.jar'
require 'jars/httpcore-4.3.1.jar'
require 'jars/httpcore-nio-4.3.1.jar'
require 'jars/netty-3.5.5.Final.jar'
require 'jars/spymemcached-2.10.5.jar'
require 'couchbase/version'
require 'uri'
require 'thread_safe'
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
require 'couchbase/design_doc'
require 'couchbase/view'
require 'couchbase/query'

include Java

at_exit do
  Couchbase.disconnect
end

# Couchbase jruby client
module Couchbase

  @@buckets     = ThreadSafe::Cache.new
  @@connections = ThreadSafe::Array.new

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
      bucket = Bucket.new(*(options.flatten))
      @@connections << bucket
      bucket
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
    attr_reader :connection_options

    def connection_options=(options)
      @connection_options = normalize_connection_options(options)
    end

    def normalize_connection_options(options)
      Hash[ options.map { |k, v| [k.to_sym, v] } ]
    end

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
                 path[%r(^(/pools/([A-Za-z0-9_.-]+)(/buckets/([A-Za-z0-9_.-]+))?)?), 3] || 'default'
               else
                 'default'
               end

      @@buckets[name] ||= connect(connection_options)
    end

    # Set a connection instance for current thread
    #
    # @since 1.1.0
    #
    # @return [Bucket]
    def bucket=(connection)
      name = @connection_options && @connection_options[:bucket] || "default"
      @@buckets[name] = connection
    end
    alias set_bucket bucket=

    def connected?
      !!@@buckets.empty?
    end

    def disconnect
      @@buckets.each_pair do |bucket, connection|
        connection.disconnect if connection.connected?
      end
      @@connections.each do |connection|
        connection.disconnect if connection.connected?
      end
      @@buckets     = ThreadSafe::Cache.new
      @@connections = ThreadSafe::Array.new
    end
  end
end

