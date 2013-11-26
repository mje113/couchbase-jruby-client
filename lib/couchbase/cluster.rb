# Author:: Couchbase <info@couchbase.com>
# Copyright:: 2011, 2012 Couchbase, Inc.
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

module Couchbase

  class ClusterError < Error::Base; end

  class Cluster

    java_import java.net.URI
    java_import com.couchbase.client.clustermanager.BucketType
    java_import com.couchbase.client.clustermanager.FlushResponse
    java_import com.couchbase.client.clustermanager.AuthType

    # Establish connection to the cluster for administration
    #
    # @param [Hash] options The connection parameter
    # @option options [String] :username The username
    # @option options [String] :password The password
    # @option options [String] :pool ("default") The pool name
    # @option options [String] :hostname ("localhost") The hostname
    # @option options [String] :port (8091) The port
    def initialize(options)
      if options[:username].nil? || options[:password].nil?
        raise ArgumentError, "username and password mandatory to connect to the cluster"
      end

      options = {
        hostname: 'localhost',
        port:     8091
      }.merge(options)

      cluster_uri = "http://#{options[:hostname]}:#{options[:port]}"

      uri_list = Array(URI.new(cluster_uri))
      @manager = Java::ComCouchbaseClient::ClusterManager.new(uri_list, options[:username], options[:password])
    end

    # List available buckets
    def list_buckets
      @manager.listBuckets
    end

    # Delete the data bucket
    #
    # @param [String] name The name of the bucket
    # @param [Hash] options
    def delete_bucket(bucket)
      @manager.deleteBucket(bucket)
    end

    # Create data bucket
    #
    # @param [String] name The name of the bucket
    # @param [Hash] options The bucket parameters
    # @option options [String] :bucket_type ("couchbase") The type of the
    #   bucket. Possible values are "memcached" and "couchbase".
    # @option options [Fixnum] :ram_quota (100) The RAM quota in megabytes.
    # @option options [Fixnum] :replica_number (1) The number of replicas of
    #   each document
    # @option options [String] :auth_type ("sasl") The authentication type.
    #   Possible values are "sasl" and "none". Note you should specify free
    #   port for "none"
    # @option options [Fixnum] :proxy_port The port for moxi
    def create_bucket(name, options = {})
      ram_quota   = options[:ram_quota] || 100
      replicas    = options[:replica_number] || 0
      flush       = options.fetch(:flush) { true }
      password    = options[:password]
      proxy_port  = options[:proxy_port]
      auth_type   = options[:auth_type] || 'sasl'
      bucket_type = options[:bucket_type] == 'memcached' ? BucketType::MEMCACHED : BucketType::COUCHBASE

      if name == 'default'
        @manager.createDefaultBucket(bucket_type, ram_quota, replicas, flush)
      elsif auth == 'sasl'
        @manager.createPortBucket(bucket_type, name, ram_quota, replicas, proxy_port, flush)
      else
        @manager.createNamedBucket(bucket_type, name, ram_quota, replicas, password, flush)
      end
      true
    rescue Java::JavaLang::RuntimeException => e
      raise ClusterError, e
    end

    def flush_bucket(bucket)
      @manager.flushBucket(bucket) == FlushResponse::OK
    end

    def update_bucket(name, options)
      # implement
    end

    def self.manage(cluster_uri, username, password, &block)
      manager = new(cluster_uri, username, password)
      yield manager
    ensure
      manager.shutdown
    end
  end

end
