module Couchbase::Operations
  module Touch

    # Update the expiry time of an item
    #
    # @since 1.0.0
    #
    # The +touch+ method allow you to update the expiration time on a given
    # key. This can be useful for situations where you want to prevent an item
    # from expiring without resetting the associated value. For example, for a
    # session database you might want to keep the session alive in the database
    # each time the user accesses a web page without explicitly updating the
    # session value, keeping the user's session active and available.
    #
    # @overload touch(key, options = {})
    #   @param key [String, Symbol] Key used to reference the value.
    #   @param options [Hash] Options for operation.
    #   @option options [Fixnum] :ttl (self.default_ttl) Expiry time for key.
    #     Values larger than 30*24*60*60 seconds (30 days) are interpreted as
    #     absolute times (from the epoch).
    #   @option options [true, false] :quiet (self.quiet) If set to +true+, the
    #     operation won't raise error for missing key, it will return +nil+.
    #
    #   @yieldparam ret [Result] the result of operation in asynchronous mode
    #     (valid attributes: +error+, +operation+, +key+).
    #
    #   @return [true, false] +true+ if the operation was successful and +false+
    #     otherwise.
    #
    #   @raise [Couchbase::Error::Connect] if connection closed (see {Bucket#reconnect})
    #
    #   @raise [ArgumentError] when passing the block in synchronous mode
    #
    #   @example Touch value using +default_ttl+
    #     c.touch("foo")
    #
    #   @example Touch value using custom TTL (10 seconds)
    #     c.touch("foo", :ttl => 10)
    #
    # @overload touch(keys)
    #   @param keys [Hash] The Hash where keys represent the keys in the
    #     database, values -- the expiry times for corresponding key. See
    #     description of +:ttl+ argument above for more information about TTL
    #     values.
    #
    #   @yieldparam ret [Result] the result of operation for each key in
    #     asynchronous mode (valid attributes: +error+, +operation+, +key+).
    #
    #   @return [Hash] Mapping keys to result of touch operation (+true+ if the
    #     operation was successful and +false+ otherwise)
    #
    #   @example Touch several values
    #     c.touch("foo" => 10, :bar => 20) #=> {"foo" => true, "bar" => true}
    #
    #   @example Touch several values in async mode
    #     c.run do
    #       c.touch("foo" => 10, :bar => 20) do |ret|
    #          ret.operation   #=> :touch
    #          ret.success?    #=> true
    #          ret.key         #=> "foo" and "bar" in separate calls
    #       end
    #     end
    #
    #   @example Touch single value
    #     c.touch("foo" => 10)             #=> true
    #
    def touch(*args, &block)
      sync_block_error if !async? && block_given?
      key, options = expand_touch_args(args)

      if key.respond_to?(:to_hash)
        multi_touch_hash(key, options)
      elsif key.respond_to?(:to_ary)
        multi_touch_array(key, options)
      else
        if async?
          java_async_touch(key, options[:ttl], &block)
        else
          success = java_touch(key, options[:ttl])
          not_found_error(!success, options)
          success
        end
      end
    end

    private

    def expand_touch_args(args)
      options = extract_options_hash(args)
      options[:ttl] ||= args.size > 1 ? args.pop : default_ttl
      key = args.pop

      [key, options]
    end

    def multi_touch_hash(keys, options = {})
      {}.tap do |results|
        keys.each_pair do |key, ttl|
          results[key] = java_touch(key, ttl)
        end
      end
    end

    def multi_touch_array(keys, options = {})
      ttl = options[:ttl] || default_ttl

      {}.tap do |results|
        keys.each do |key|
          results[key] = java_touch(key, ttl)
        end
      end
    end

    def java_touch(key, ttl, options = {})
      client.touch(key, ttl).get
    end

    def java_async_touch(key, ttl, &block)
      register_future(client.touch(key, ttl), { op: :touch }, &block)
    end

  end
end
