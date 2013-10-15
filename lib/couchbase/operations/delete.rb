module Couchbase::Operations
  module Delete

    # Delete the specified key
    #
    # @since 1.0.0
    #
    # @overload delete(key, options = {})
    #   @param key [String, Symbol] Key used to reference the value.
    #   @param options [Hash] Options for operation.
    #   @option options [true, false] :quiet (self.quiet) If set to +true+, the
    #     operation won't raise error for missing key, it will return +nil+.
    #     Otherwise it will raise error in synchronous mode. In asynchronous
    #     mode this option ignored.
    #   @option options [Fixnum] :cas The CAS value for an object. This value
    #     created on the server and is guaranteed to be unique for each value of
    #     a given key. This value is used to provide simple optimistic
    #     concurrency control when multiple clients or threads try to
    #     update/delete an item simultaneously.
    #
    #   @raise [Couchbase::Error::Connect] if connection closed (see {Bucket#reconnect})
    #   @raise [ArgumentError] when passing the block in synchronous mode
    #   @raise [Couchbase::Error::KeyExists] on CAS mismatch
    #   @raise [Couchbase::Error::NotFound] if key is missing in verbose mode
    #
    #   @return [true, false, Hash<String, Boolean>] the result of the
    #     operation
    #
    #   @example Delete the key in quiet mode (default)
    #     c.set("foo", "bar")
    #     c.delete("foo")        #=> true
    #     c.delete("foo")        #=> false
    #
    #   @example Delete the key verbosely
    #     c.set("foo", "bar")
    #     c.delete("foo", :quiet => false)   #=> true
    #     c.delete("foo", :quiet => true)    #=> nil (default behaviour)
    #     c.delete("foo", :quiet => false)   #=> will raise Couchbase::Error::NotFound
    #
    #   @example Delete the key with version check
    #     ver = c.set("foo", "bar")          #=> 5992859822302167040
    #     c.delete("foo", :cas => 123456)    #=> will raise Couchbase::Error::KeyExists
    #     c.delete("foo", :cas => ver)       #=> true
    #
    def delete(*args, &block)
      sync_block_error if !async? && block_given?
      key, options = expand_get_args(args)
      key, cas     = delete_args_parser(key)

      if key.respond_to?(:to_ary)
        delete_multi(key, options)
      else
        delete_single(key, cas, options, &block)
      end
    end

    private

    def delete_args_parser(args)
      if args.respond_to?(:to_str)
        [args, nil]
      else
        cas = if args.size > 1 &&
                 args.last.respond_to?(:to_int)
                args.pop
              else
                nil
              end

        key = args.size == 1 ? args.first : args

        [key, cas]
      end
    end

    def delete_single(key, cas, options, &block)
      if async?
        java_async_delete(key, &block)
      else
        cas = java_delete(key)
        not_found_error(!cas, options)
        cas
      end
    end

    def delete_multi(keys, options = {})
      {}.tap do |results|
        keys.each do |key|
          results[key] = delete_single(key, nil, options)
        end
      end
    end

    def java_delete(key)
      future = client.delete(key)
      future_cas(future)
    end

    def java_async_delete(key, &block)
      future = client.delete(key)
      register_future(future, { op: :delete }, &block)
    end
  end
end
