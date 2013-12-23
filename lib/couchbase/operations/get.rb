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

module Couchbase::Operations
  module Get

    # Obtain an object stored in Couchbase by given key.
    #
    # @since 1.0.0
    #
    # @see http://couchbase.com/docs/couchbase-manual-2.0/couchbase-architecture-apis-memcached-protocol-additions.html#couchbase-architecture-apis-memcached-protocol-additions-getl
    #
    # @overload get(*keys, options = {})
    #   @param keys [String, Symbol, Array] One or several keys to fetch
    #   @param options [Hash] Options for operation.
    #   @option options [true, false] :extended (false) If set to +true+, the
    #     operation will return a tuple +[value, flags, cas]+, otherwise (by
    #     default) it returns just the value.
    #   @option options [Fixnum] :ttl (self.default_ttl) Expiry time for key.
    #     Values larger than 30*24*60*60 seconds (30 days) are interpreted as
    #     absolute times (from the epoch).
    #   @option options [true, false] :quiet (self.quiet) If set to +true+, the
    #     operation won't raise error for missing key, it will return +nil+.
    #     Otherwise it will raise error in synchronous mode. In asynchronous
    #     mode this option ignored.
    #   @option options [Symbol] :format (nil) Explicitly choose the decoder
    #     for this key (+:plain+, +:document+, +:marshal+). See
    #     {Bucket#default_format}.
    #   @option options [Fixnum, Boolean] :lock Lock the keys for time span.
    #     If this parameter is +true+ the key(s) will be locked for default
    #     timeout. Also you can use number to setup your own timeout in
    #     seconds. If it will be lower that zero or exceed the maximum, the
    #     server will use default value. You can determine actual default and
    #     maximum values calling {Bucket#stats} without arguments and
    #     inspecting keys  "ep_getl_default_timeout" and "ep_getl_max_timeout"
    #     correspondingly. See overloaded hash syntax to specify custom timeout
    #     per each key.
    #   @option options [true, false] :assemble_hash (false) Assemble Hash for
    #     results. Hash assembled automatically if +:extended+ option is true
    #     or in case of "get and touch" multimple keys.
    #   @option options [true, false] :replica (false) Read key from replica
    #     node. Options +:ttl+ and +:lock+ are not compatible with +:replica+.
    #
    #   @yieldparam ret [Result] the result of operation in asynchronous mode
    #     (valid attributes: +error+, +operation+, +key+, +value+, +flags+,
    #     +cas+).
    #
    #   @return [Object, Array, Hash] the value(s) (or tuples in extended mode)
    #     associated with the key.
    #
    #   @raise [Couchbase::Error::NotFound] if the key is missing in the
    #     bucket.
    #
    #   @raise [Couchbase::Error::Connect] if connection closed (see {Bucket#reconnect})
    #
    #   @raise [ArgumentError] when passing the block in synchronous mode
    #
    #   @example Get single value in quiet mode (the default)
    #     c.get("foo")     #=> the associated value or nil
    #
    #   @example Use alternative hash-like syntax
    #     c["foo"]         #=> the associated value or nil
    #
    #   @example Get single value in verbose mode
    #     c.get("missing-foo", :quiet => false)  #=> raises Couchbase::NotFound
    #     c.get("missing-foo", :quiet => true)   #=> returns nil
    #
    #   @example Get and touch single value. The key won't be accessible after 10 seconds
    #     c.get("foo", :ttl => 10)
    #
    #   @example Extended get
    #     val, flags, cas = c.get("foo", :extended => true)
    #
    #   @example Get multiple keys
    #     c.get("foo", "bar", "baz")   #=> [val1, val2, val3]
    #
    #   @example Get multiple keys with assembing result into the Hash
    #     c.get("foo", "bar", "baz", :assemble_hash => true)
    #     #=> {"foo" => val1, "bar" => val2, "baz" => val3}
    #
    #   @example Extended get multiple keys
    #     c.get("foo", "bar", :extended => true)
    #     #=> {"foo" => [val1, flags1, cas1], "bar" => [val2, flags2, cas2]}
    #
    #   @example Asynchronous get
    #     c.run do
    #       c.get("foo", "bar", "baz") do |res|
    #         ret.operation   #=> :get
    #         ret.success?    #=> true
    #         ret.key         #=> "foo", "bar" or "baz" in separate calls
    #         ret.value
    #         ret.flags
    #         ret.cas
    #       end
    #     end
    #
    #   @example Get and lock key using default timeout
    #     c.get("foo", :lock => true)
    #
    #   @example Determine lock timeout parameters
    #     c.stats.values_at("ep_getl_default_timeout", "ep_getl_max_timeout")
    #     #=> [{"127.0.0.1:11210"=>"15"}, {"127.0.0.1:11210"=>"30"}]
    #
    #   @example Get and lock key using custom timeout
    #     c.get("foo", :lock => 3)
    #
    #   @example Get and lock multiple keys using custom timeout
    #     c.get("foo", "bar", :lock => 3)
    #
    # @overload get(keys, options = {})
    #   When the method receive hash map, it will behave like it receive list
    #   of keys (+keys.keys+), but also touch each key setting expiry time to
    #   the corresponding value. But unlike usual get this command always
    #   return hash map +{key => value}+ or +{key => [value, flags, cas]}+.
    #
    #   @param keys [Hash] Map key-ttl
    #   @param options [Hash] Options for operation. (see options definition
    #     above)
    #
    #   @return [Hash] the values (or tuples in extended mode) associated with
    #     the keys.
    #
    #   @example Get and touch multiple keys
    #     c.get("foo" => 10, "bar" => 20)   #=> {"foo" => val1, "bar" => val2}
    #
    #   @example Extended get and touch multiple keys
    #     c.get({"foo" => 10, "bar" => 20}, :extended => true)
    #     #=> {"foo" => [val1, flags1, cas1], "bar" => [val2, flags2, cas2]}
    #
    #   @example Get and lock multiple keys for chosen period in seconds
    #     c.get("foo" => 10, "bar" => 20, :lock => true)
    #     #=> {"foo" => val1, "bar" => val2}
    #
    def get(*args, &block)
      key, options = expand_get_args(args)
      get_key(key, options)
    end

    def [](key, options = {})
      get(key, options)
    end

    def get_bulk(keys, options)
      results = if options[:extended]
                  get_bulk_extended(keys, options)
                else
                  client_get_bulk(keys)
                end

      not_found_error(results.size != keys.size, options)

      if options[:assemble_hash] || options[:extended]
        results
      else
        ordered_multi_values(keys, results)
      end
    end

    def async_get(key, &block)
      fail ArgumentError, 'Must pass a block to #async_get' unless block_given?

      case key
      when String, Symbol
        meta = { op: :get, key: key }
        future = client.asyncGet(key)
      when Array
        meta = { op: :get }
        future = client.asyncGetBulk(key)
      when Hash
        # async_get_and_touch(key, options, &block)
      end
      register_future(future, meta, &block)
    end

    private

    def get_key(key, options)
      case key
      when String, Symbol
        get_single(key, options)
      when Array
        get_bulk(key, options)
      when Hash
        get_and_touch(key, options)
      end
    end

    def expand_get_args(args)
      options = extract_options_hash(args)
      key = args.size == 1 ? args.first : args

      [key, options]
    end

    def get_single(key, options)
      if options[:lock]
        client_get_and_lock(key, options)
      elsif options[:extended]
        get_extended(key, options)
      else
        value = if options.key?(:ttl)
                  client_get_and_touch(key, options[:ttl])
                elsif options[:format]
                  client.get(key, transcoders[options[:format]])
                else
                  client.get(key)
                end

        not_found_error(value.nil?, options)
        value.nil? ? nil : value
      end
    rescue Java::JavaLang::RuntimeException
      get_single(key, options.merge(format: :plain))
    end

    def get_extended(key, options = {})
      if options.key?(:lock)
        client_get_and_lock(key, options[:lock])
      end
      extended = client_get_extended(key)
      not_found_error(extended.nil?, options)
      extended
    end

    def get_and_touch(key, options = {})
      if key.size > 1
        get_bulk_and_touch(key, options)
      else
        key, ttl = key.first
        value = client_get_and_touch(key, ttl)
        not_found_error(value.nil?)
        { key => value }
      end
    end

    def get_bulk_and_touch(keys, options = {})
      options.merge!(assemble_hash: true)
      results = get_bulk(keys.keys, options)
      touch(keys)
      results.to_hash
    end

    def get_bulk_extended(keys, options = {})
      {}.tap do |results|
        keys.each do |key|
          result = get_extended(key, options)
          results[key] = result unless result.nil?
        end
      end
    end

    def ordered_multi_values(keys, results)
      keys.map { |key| results[key] }
    end

    def client_get_and_touch(key, ttl)
      client.getAndTouch(key, ttl).getValue
    end

    def client_get_and_lock(key, options)
      lock = options[:lock] == true ? 30 : options[:lock]
      cas = client.getAndLock(key, lock)
      if options[:extended]
        [cas.getValue, nil, cas.getCas]
      else
        cas.getValue
      end
    end

    def client_get_extended(key)
      cas_value = client.gets(key)

      if cas_value.nil?
        nil
      else
        [cas_value.getValue, nil, cas_value.getCas]
      end
    end

    def client_get_bulk(keys)
      client.getBulk(keys)
    rescue java.lang.ClassCastException
      raise TypeError.new
    end
  end
end
