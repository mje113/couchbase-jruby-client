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

module Couchbase

  class Bucket

    java_import java.io.IOException
    java_import java.net.SocketAddress
    java_import java.net.URI
    java_import java.net.URISyntaxException
    java_import java.util.ArrayList
    java_import java.util.LinkedList
    java_import java.util.List
    java_import java.util.concurrent.Future
    java_import java.util.concurrent.TimeUnit
    java_import com.couchbase.client.CouchbaseClient
    java_import com.couchbase.client.CouchbaseConnectionFactory
    java_import com.couchbase.client.CouchbaseConnectionFactoryBuilder

    include Couchbase::Operations
    include Couchbase::Async

    attr_accessor :quiet, :hostname, :port, :pool, :bucket, :username,
                  :password, :default_ttl, :timeout, :default_format,
                  :default_arithmetic_init, :transcoder, :transcoders

    attr_reader :client, :key_prefix, :default_format

    DEFAULT_OPTIONS = {
      type:                      nil,
      quiet:                     false,
      hostname:                  'localhost',
      port:                      8091,
      pool:                      'default',
      bucket:                    'default',
      password:                  '',
      engine:                    nil,
      default_ttl:               0,
      async:                     false,
      default_arithmetic_init:   0,
      default_flags:             0,
      default_format:            :document,
      default_observe_timeout:   2_500_000,
      on_error:                  nil,
      on_connect:                nil,
      timeout:                   0,
      environment:               nil,
      key_prefix:                nil,
      node_list:                 nil,
      destroying:                0,
      connected:                 0,
      on_connect_proc:           nil,
      async_disconnect_hook_set: 0,
      connected:                 false
    }.freeze

    # Initialize new Bucket.
    #
    # @since 1.0.0
    #
    # @overload initialize(url, options = {})
    #   Initialize bucket using URI of the cluster and options. It is possible
    #   to override some parts of URI using the options keys (e.g. :host or
    #   :port)
    #
    #   @param [String] url The full URL of management API of the cluster.
    #   @param [Hash] options The options for connection. See options definition
    #     below.
    #
    # @overload initialize(options = {})
    #   Initialize bucket using options only.
    #
    #   @param [Hash] options The options for operation for connection
    #   @option options [Array] :node_list (nil) the list of nodes to connect
    #     to. If specified it takes precedence over +:host+ option. The list
    #     must be array of strings in form of host names or host names with
    #     ports (in first case port 8091 will be used, see examples).
    #   @option options [String] :host ("localhost") the hostname or IP address
    #     of the node
    #   @option options [Fixnum] :port (8091) the port of the managemenent API
    #   @option options [String] :pool ("default") the pool name
    #   @option options [String] :bucket ("default") the bucket name
    #   @option options [Fixnum] :default_ttl (0) the TTL used by default during
    #     storing key-value pairs.
    #   @option options [Fixnum] :default_flags (0) the default flags.
    #   @option options [Symbol] :default_format (:document) the format, which
    #     will be used for values by default. Note that changing format will
    #     amend flags. (see {Bucket#default_format})
    #   @option options [String] :username (nil) the user name to connect to the
    #     cluster. Used to authenticate on management API. The username could
    #     be skipped for protected buckets, the bucket name will be used
    #     instead.
    #   @option options [String] :password (nil) the password of the user.
    #   @option options [true, false] :quiet (false) the flag controlling if raising
    #     exception when the client executes operations on non-existent keys. If it
    #     is +true+ it will raise {Couchbase::Error::NotFound} exceptions. The
    #     default behaviour is to return +nil+ value silently (might be useful in
    #     Rails cache).
    #   @option options [Symbol] :environment (:production) the mode of the
    #     connection. Currently it influences only on design documents set. If
    #     the environment is +:development+, you will able to get design
    #     documents with 'dev_' prefix, otherwise (in +:production+ mode) the
    #     library will hide them from you.
    #   @option options [String] :key_prefix (nil) the prefix string which will
    #     be prepended to each key before sending out, and sripped before
    #     returning back to the application.
    #   @option options [Fixnum] :timeout (2500000) the timeout for IO
    #     operations (in microseconds)
    #   @option options [Fixnum, true] :default_arithmetic_init (0) the default
    #     initial value for arithmetic operations. Setting this option to any
    #     non positive number forces creation missing keys with given default
    #     value. Setting it to +true+ will use zero as initial value. (see
    #     {Bucket#incr} and {Bucket#decr}).
    #   @option options [Symbol] :engine (:default) the IO engine to use
    #     Currently following engines are supported:
    #     :default      :: Built-in engine (multi-thread friendly)
    #     :libevent     :: libevent IO plugin from libcouchbase (optional)
    #     :libev        :: libev IO plugin from libcouchbase (optional)
    #     :eventmachine :: EventMachine plugin (builtin, but requires EM gem and ruby 1.9+)
    #   @option options [true, false] :async (false) If true, the
    #     connection instance will be considered always asynchronous and
    #     IO interaction will be occured only when {Couchbase::Bucket#run}
    #     called. See {Couchbase::Bucket#on_connect} to hook your code
    #     after the instance will be connected.
    #
    # @example Initialize connection using default options
    #   Couchbase.new
    #
    # @example Select custom bucket
    #   Couchbase.new(:bucket => 'foo')
    #   Couchbase.new('http://localhost:8091/pools/default/buckets/foo')
    #
    # @example Connect to protected bucket
    #   Couchbase.new(:bucket => 'protected', :username => 'protected', :password => 'secret')
    #   Couchbase.new('http://localhost:8091/pools/default/buckets/protected',
    #                 :username => 'protected', :password => 'secret')
    #
    # @example Use list of nodes, in case some nodes might be dead
    #   Couchbase.new(:node_list => ['example.com:8091', 'example.org:8091', 'example.net'])
    #
    # @raise [Couchbase::Error::BucketNotFound] if there is no such bucket to
    #   connect to
    #
    # @raise [Couchbase::Error::Connect] if the socket wasn't accessible
    #   (doesn't accept connections or doesn't respond in time)
    #
    # @return [Bucket]
    #
    def initialize(url = nil, options = {})
      url_options = if url.is_a? String
                      fail ArgumentError.new unless url =~ /^http:\/\//
                      uri = URI.new(url)
                      { hostname: uri.host, port: uri.port }.
                        merge(path_to_pool_and_bucket(uri.path))
                    elsif url.nil?
                      {}
                    else
                      url
                    end

      options = Couchbase.normalize_connection_options(options)

      connection_options = DEFAULT_OPTIONS.merge(url_options).merge(options)

      connection_options.each_pair do |key, value|
        instance_variable_set("@#{key}", value)
      end

      self.password = '' if self.password.nil?

      @transcoders = {
        document: Transcoder::Document.new,
        marshal:  Transcoder::Marshal.new,
        plain:    Transcoder::Plain.new
      }

      connect unless async?
    end

    def quiet?
      !!quiet
    end

    def host
      hostname
    end

    def connect
      uris = if @node_list
               Array(@node_list).map { |n| URI.new(n) }
             else
               Array(URI.new(base_url))
             end

      begin
        builder = CouchbaseConnectionFactoryBuilder.new
        builder.setTranscoder(transcoder)
        connection_factory = builder.buildCouchbaseConnection(uris, bucket.to_java_string, password.to_java_string)
        @client = CouchbaseClient.new(connection_factory)
        @connected = true
      rescue Java::ComCouchbaseClientVbucket::ConfigurationException => e
        fail Couchbase::Error::Auth, "Couchbase configurations are incorrect: #{e.to_s}"
      rescue java.net.ConnectException => e
        fail Couchbase::Error::Connect, e.to_s
      end

      self
    end
    alias_method :reconnect, :connect

    def authority
      "#{hostname}:#{port}"
    end

    def base_url
      "http://#{authority}/pools"
    end

    def url
      "http://#{authority}/pools/#{pool}/buckets/#{bucket}/"
    end

    def connected?
      @connected
    end

    def disconnect
      if connected?
        @client.shutdown(5, TimeUnit::SECONDS)
        @client = nil
        @connection_factory = nil
        @connected = false
      else
        fail Couchbase::Error::Connect
      end
    end

    def transcoder
      transcoders[default_format]
    end

    def on_connect(&block)
      @on_connect = block
    end

    def on_error(&block)
      @on_error = block
    end

    def version
      {}.tap do |hash|
        @client.getVersions.to_hash.each_pair do |ip, ver|
          hash[ip.to_s] = ver
        end
      end
    end

    # Compare and swap value.
    #
    # @since 1.0.0
    #
    # Reads a key's value from the server and yields it to a block. Replaces
    # the key's value with the result of the block as long as the key hasn't
    # been updated in the meantime, otherwise raises
    # {Couchbase::Error::KeyExists}. CAS stands for "compare and swap", and
    # avoids the need for manual key mutexing. Read more info here:
    #
    # In asynchronous mode it will yield result twice, first for
    # {Bucket#get} with {Result#operation} equal to +:get+ and
    # second time for {Bucket#set} with {Result#operation} equal to +:set+.
    #
    # @see http://couchbase.com/docs/memcached-api/memcached-api-protocol-text_cas.html
    #
    # @param [String, Symbol] key
    #
    # @param [Hash] options the options for "swap" part
    # @option options [Fixnum] :ttl (self.default_ttl) the time to live of this key
    # @option options [Symbol] :format (self.default_format) format of the value
    # @option options [Fixnum] :flags (self.default_flags) flags for this key
    #
    # @yieldparam [Object, Result] value old value in synchronous mode and
    #   +Result+ object in asynchronous mode.
    # @yieldreturn [Object] new value.
    #
    # @raise [Couchbase::Error::KeyExists] if the key was updated before the the
    #   code in block has been completed (the CAS value has been changed).
    # @raise [ArgumentError] if the block is missing for async mode
    #
    # @example Implement append to JSON encoded value
    #
    #     c.default_format = :document
    #     c.set("foo", {"bar" => 1})
    #     c.cas("foo") do |val|
    #       val["baz"] = 2
    #       val
    #     end
    #     c.get("foo")      #=> {"bar" => 1, "baz" => 2}
    #
    # @example Append JSON encoded value asynchronously
    #
    #     c.default_format = :document
    #     c.set("foo", {"bar" => 1})
    #     c.run do
    #       c.cas("foo") do |val|
    #         case val.operation
    #         when :get
    #           val["baz"] = 2
    #           val
    #         when :set
    #           # verify all is ok
    #           puts "error: #{ret.error.inspect}" unless ret.success?
    #         end
    #       end
    #     end
    #     c.get("foo")      #=> {"bar" => 1, "baz" => 2}
    #
    # @return [Fixnum] the CAS of new value
    def cas(key, options = {})
      if async?
        block = Proc.new
        get(key) do |ret|
          val = block.call(ret) # get new value from caller
          set(ret.key, val, options.merge(:cas => ret.cas, &block))
        end
      else
        val, flags, ver = get(key, :extended => true)
        val = yield(val) # get new value from caller
        set(key, val, options.merge(:cas => ver))
      end
    end
    alias :compare_and_swap :cas

    # Delete contents of the bucket
    #
    # @see http://www.couchbase.com/docs/couchbase-manual-2.0/restapi-flushing-bucket.html
    #
    # @since 1.2.0.beta
    #
    # @yieldparam [Result] ret the object with +error+, +status+ and +operation+
    #   attributes.
    #
    # @raise [Couchbase::Error::Protocol] in case of an error is
    #   encountered. Check {Couchbase::Error::Base#status} for detailed code.
    #
    # @return [true] always return true (see raise section)
    #
    # @example Simple flush the bucket
    #   c.flush    #=> true
    #
    # @example Asynchronous flush
    #   c.run do
    #     c.flush do |ret|
    #       ret.operation   #=> :flush
    #       ret.success?    #=> true
    #       ret.status      #=> 200
    #     end
    #   end
    def flush
      @client.flush
      true
    end

    # Create and register one-shot timer
    #
    # @return [Couchbase::Timer]
    def create_timer(interval, &block)
      Timer.new(self, interval, &block)
    end

    # Create and register periodic timer
    #
    # @return [Couchbase::Timer]
    def create_periodic_timer(interval, &block)
      Timer.new(self, interval, :periodic => true, &block)
    end

    # Wait for persistence condition
    #
    # @since 1.2.0.dp6
    #
    # This operation is useful when some confidence needed regarding the
    # state of the keys. With two parameters +:replicated+ and +:persisted+
    # it allows to set up the waiting rule.
    #
    # @param [String, Symbol, Array, Hash] keys The list of the keys to
    #   observe. Full form is hash with key-cas value pairs, but there are
    #   also shortcuts like just Array of keys or single key. CAS value
    #   needed to when you need to ensure that the storage persisted exactly
    #   the same version of the key you are asking to observe.
    # @param [Hash] options The options for operation
    # @option options [Fixnum] :timeout The timeout in microseconds
    # @option options [Fixnum] :replicated How many replicas should receive
    #   the copy of the key.
    # @option options [Fixnum] :persisted How many nodes should store the
    #   key on the disk.
    #
    # @raise [Couchbase::Error::Timeout] if the given time is up
    #
    # @return [Fixnum, Hash<String, Fixnum>] will return CAS value just like
    #   mutators or pairs key-cas in case of multiple keys.
    def observe_and_wait(*keys, &block)
      options = {:timeout => default_observe_timeout}
      options.update(keys.pop) if keys.size > 1 && keys.last.is_a?(Hash)
      verify_observe_options(options)
      if block && !async?
        raise ArgumentError, "synchronous mode doesn't support callbacks"
      end
      if keys.size == 0
        raise ArgumentError, "at least one key is required"
      end
      if keys.size == 1 && keys[0].is_a?(Hash)
        key_cas = keys[0]
      else
        key_cas = keys.flatten.reduce({}) do |h, kk|
          h[kk] = nil   # set CAS to nil
          h
        end
      end
      if async?
        do_observe_and_wait(key_cas, options, &block)
      else
        res = do_observe_and_wait(key_cas, options, &block) while res.nil?
        unless async?
          if keys.size == 1 && (keys[0].is_a?(String) || keys[0].is_a?(Symbol))
            return res.values.first
          else
            return res
          end
        end
      end
    end

    private

    def path_to_pool_and_bucket(path)
      {}
    end

    def verify_observe_options(options)
      unless num_replicas
        raise Couchbase::Error::Libcouchbase, "cannot detect number of the replicas"
      end
      unless options[:persisted] || options[:replicated]
        raise ArgumentError, "either :persisted or :replicated option must be set"
      end
      if options[:persisted] && !(1..num_replicas + 1).include?(options[:persisted])
        raise ArgumentError, "persisted number should be in range (1..#{num_replicas + 1})"
      end
      if options[:replicated] && !(1..num_replicas).include?(options[:replicated])
        raise ArgumentError, "replicated number should be in range (1..#{num_replicas})"
      end
    end

    def do_observe_and_wait(keys, options, &block)
      acc = Hash.new do |h, k|
        h[k] = Hash.new(0)
        h[k][:cas] = [keys[k]] # first position is for master node
        h[k]
      end
      check_condition = lambda do
        ok = catch :break do
          acc.each do |key, stats|
            master = stats[:cas][0]
            if master.nil?
              # master node doesn't have the key
              throw :break
            end
            if options[:persisted] && (stats[:persisted] < options[:persisted] ||
                                       stats[:cas].count(master) != options[:persisted])
              throw :break
            end
            if options[:replicated] && (stats[:replicated] < options[:replicated] ||
                                        stats[:cas].count(master) != options[:replicated] + 1)
              throw :break
            end
          end
          true
        end
        if ok
          if async?
            options[:timer].cancel if options[:timer]
            keys.each do |k, _|
              block.call(Result.new(:key => k,
                                    :cas => acc[k][:cas][0],
                                    :operation => :observe_and_wait))
            end
            return :async
          else
            return keys.inject({}){|res, (k, _)| res[k] = acc[k][:cas][0]; res}
          end
        else
          options[:timeout] /= 2
          if options[:timeout] > 0
            if async?
              options[:timer] = create_timer(options[:timeout]) do
                do_observe_and_wait(keys, options, &block)
              end
              return :async
            else
              # do wait for timeout
              run { create_timer(options[:timeout]){} }
              # return nil to avoid recursive call
              return nil
            end
          else
            err = Couchbase::Error::Timeout.new("the observe request was timed out")
            err.instance_variable_set("@operation", :observe_and_wait)
            if async?
              keys.each do |k, _|
                block.call(Result.new(:key => k,
                                      :cas => acc[k][:cas][0],
                                      :operation => :observe_and_wait,
                                      :error => err))
              end
              return :async
            else
              err.instance_variable_set("@key", keys.keys)
              raise err
            end
          end
        end
      end
      collect = lambda do |results|
        results.each do |res|
          if res.completed?
            check_condition.call if async?
          else
            if res.from_master?
              acc[res.key][:cas][0] = res.cas
            else
              acc[res.key][:cas] << res.cas
            end
            acc[res.key][res.status] += 1
            if res.status == :persisted
              acc[res.key][:replicated] += 1
            end
          end
        end
      end
      if async?
        observe(keys.keys, options, &collect)
      else
        observe(keys.keys, options).each{|_, v| collect.call(v)}
        check_condition.call
      end
    end
  end

end
