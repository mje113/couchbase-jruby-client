module Couchbase::Operations
  module Store

    # Unconditionally store the object in the Couchbase
    #
    # @since 1.0.0
    #
    # @overload set(key, value, options = {})
    #
    #   @param key [String, Symbol] Key used to reference the value.
    #   @param value [Object] Value to be stored
    #   @param options [Hash] Options for operation.
    #   @option options [Fixnum] :ttl (self.default_ttl) Expiry time for key.
    #     Values larger than 30*24*60*60 seconds (30 days) are interpreted as
    #     absolute times (from the epoch).
    #   @option options [Fixnum] :flags (self.default_flags) Flags for storage
    #     options. Flags are ignored by the server but preserved for use by the
    #     client. For more info see {Bucket#default_flags}.
    #   @option options [Symbol] :format (self.default_format) The
    #     representation for storing the value in the bucket. For more info see
    #     {Bucket#default_format}.
    #   @option options [Fixnum] :cas The CAS value for an object. This value is
    #     created on the server and is guaranteed to be unique for each value of
    #     a given key. This value is used to provide simple optimistic
    #     concurrency control when multiple clients or threads try to update an
    #     item simultaneously.
    #   @option options [Hash] :observe Apply persistence condition before
    #     returning result. When this option specified the library will observe
    #     given condition. See {Bucket#observe_and_wait}.
    #
    #   @yieldparam ret [Result] the result of operation in asynchronous mode
    #     (valid attributes: +error+, +operation+, +key+).
    #
    #   @return [Fixnum] The CAS value of the object.
    #
    #   @raise [Couchbase::Error::Connect] if connection closed (see {Bucket#reconnect}).
    #   @raise [Couchbase::Error::KeyExists] if the key already exists on the
    #     server.
    #   @raise [Couchbase::Error::ValueFormat] if the value cannot be serialized
    #     with chosen encoder, e.g. if you try to store the Hash in +:plain+
    #     mode.
    #   @raise [ArgumentError] when passing the block in synchronous mode
    #   @raise [Couchbase::Error::Timeout] if timeout interval for observe
    #     exceeds
    #
    #   @example Store the key which will be expired in 2 seconds using relative TTL.
    #     c.set("foo", "bar", :ttl => 2)
    #
    #   @example Perform multi-set operation. It takes a Hash store its keys/values into the bucket
    #     c.set("foo1" => "bar1", "foo2" => "bar2")
    #     #=> {"foo1" => cas1, "foo2" => cas2}
    #
    #   @example More advanced multi-set using asynchronous mode
    #     c.run do
    #       # fire and forget
    #       c.set("foo1", "bar1", :ttl => 10)
    #       # receive result into the callback
    #       c.set("foo2", "bar2", :ttl => 10) do |ret|
    #         if ret.success?
    #           puts ret.cas
    #         end
    #       end
    #     end
    #
    #   @example Store the key which will be expired in 2 seconds using absolute TTL.
    #     c.set("foo", "bar", :ttl => Time.now.to_i + 2)
    #
    #   @example Force JSON document format for value
    #     c.set("foo", {"bar" => "baz}, :format => :document)
    #
    #   @example Use hash-like syntax to store the value
    #     c["foo"] = {"bar" => "baz}
    #
    #   @example Use extended hash-like syntax
    #     c["foo", {:flags => 0x1000, :format => :plain}] = "bar"
    #     c["foo", :flags => 0x1000] = "bar"  # for ruby 1.9.x only
    #
    #   @example Set application specific flags (note that it will be OR-ed with format flags)
    #     c.set("foo", "bar", :flags => 0x1000)
    #
    #   @example Perform optimistic locking by specifying last known CAS version
    #     c.set("foo", "bar", :cas => 8835713818674332672)
    #
    #   @example Perform asynchronous call
    #     c.run do
    #       c.set("foo", "bar") do |ret|
    #         ret.operation   #=> :set
    #         ret.success?    #=> true
    #         ret.key         #=> "foo"
    #         ret.cas
    #       end
    #     end
    #
    #   @example Ensure that the key will be persisted at least on the one node
    #     c.set("foo", "bar", :observe => {:persisted => 1})
    #
    def set(key, value = nil, options = {})
      op, key, value, ttl = store_args_parser(key, value, options)

      if async?
        if block_given?
          async_set(key, value, ttl, &Proc.new)
        else
          async_set(key, value, ttl)
        end
      else
        sync_block_error if block_given?

        if op == :single
          set_single(key, value, ttl, options)
        else
          set_multi(key)
        end
      end
    end

    def async_set(key, value, ttl)
      future = client.set(key.to_s, ttl, dump(value))
      register_future(future, { op: :set }, &Proc.new) if block_given?
    end

    def []=(key, *args)
      options = args.size > 1 ? args.shift : {}
      value   = args.pop

      set(key, value, options)
    end

    # Add the item to the database, but fail if the object exists already
    #
    # @since 1.0.0
    #
    # @overload add(key, value, options = {})
    #
    #   @param key [String, Symbol] Key used to reference the value.
    #   @param value [Object] Value to be stored
    #   @param options [Hash] Options for operation.
    #   @option options [Fixnum] :ttl (self.default_ttl) Expiry time for key.
    #     Values larger than 30*24*60*60 seconds (30 days) are interpreted as
    #     absolute times (from the epoch).
    #   @option options [Fixnum] :flags (self.default_flags) Flags for storage
    #     options. Flags are ignored by the server but preserved for use by the
    #     client. For more info see {Bucket#default_flags}.
    #   @option options [Symbol] :format (self.default_format) The
    #     representation for storing the value in the bucket. For more info see
    #     {Bucket#default_format}.
    #   @option options [Fixnum] :cas The CAS value for an object. This value
    #     created on the server and is guaranteed to be unique for each value of
    #     a given key. This value is used to provide simple optimistic
    #     concurrency control when multiple clients or threads try to update an
    #     item simultaneously.
    #   @option options [Hash] :observe Apply persistence condition before
    #     returning result. When this option specified the library will observe
    #     given condition. See {Bucket#observe_and_wait}.
    #
    #   @yieldparam ret [Result] the result of operation in asynchronous mode
    #     (valid attributes: +error+, +operation+, +key+).
    #
    #   @return [Fixnum] The CAS value of the object.
    #
    #   @raise [Couchbase::Error::Connect] if connection closed (see {Bucket#reconnect})
    #   @raise [Couchbase::Error::KeyExists] if the key already exists on the
    #     server
    #   @raise [Couchbase::Error::ValueFormat] if the value cannot be serialized
    #     with chosen encoder, e.g. if you try to store the Hash in +:plain+
    #     mode.
    #   @raise [ArgumentError] when passing the block in synchronous mode
    #   @raise [Couchbase::Error::Timeout] if timeout interval for observe
    #     exceeds
    #
    #   @example Add the same key twice
    #     c.add("foo", "bar")  #=> stored successully
    #     c.add("foo", "baz")  #=> will raise Couchbase::Error::KeyExists: failed to store value (key="foo", error=0x0c)
    #
    #   @example Ensure that the key will be persisted at least on the one node
    #     c.add("foo", "bar", :observe => {:persisted => 1})
    #
    def add(key, value = nil, options = {})
      op, key, value, ttl = store_args_parser(key, value, options)

      if async?
        if block_given?
          async_add(key, value, ttl, &Proc.new)
        else
          async_add(key, value, ttl)
        end
      else
        sync_block_error if block_given?

        if op == :single
          add_single(key, value, ttl, options)
        else
          add_multi(key)
        end
      end
    end

    def async_add(key, value, ttl)
      future = client.add(key.to_s, ttl, dump(value))
      register_future(future, { op: :add }, &Proc.new) if block_given?
    end

    # Replace the existing object in the database
    #
    # @since 1.0.0
    #
    # @overload replace(key, value, options = {})
    #   @param key [String, Symbol] Key used to reference the value.
    #   @param value [Object] Value to be stored
    #   @param options [Hash] Options for operation.
    #   @option options [Fixnum] :ttl (self.default_ttl) Expiry time for key.
    #     Values larger than 30*24*60*60 seconds (30 days) are interpreted as
    #     absolute times (from the epoch).
    #   @option options [Fixnum] :flags (self.default_flags) Flags for storage
    #     options. Flags are ignored by the server but preserved for use by the
    #     client. For more info see {Bucket#default_flags}.
    #   @option options [Symbol] :format (self.default_format) The
    #     representation for storing the value in the bucket. For more info see
    #     {Bucket#default_format}.
    #   @option options [Fixnum] :cas The CAS value for an object. This value
    #     created on the server and is guaranteed to be unique for each value of
    #     a given key. This value is used to provide simple optimistic
    #     concurrency control when multiple clients or threads try to update an
    #     item simultaneously.
    #   @option options [Hash] :observe Apply persistence condition before
    #     returning result. When this option specified the library will observe
    #     given condition. See {Bucket#observe_and_wait}.
    #
    #   @return [Fixnum] The CAS value of the object.
    #
    #   @raise [Couchbase::Error::Connect] if connection closed (see {Bucket#reconnect})
    #   @raise [Couchbase::Error::NotFound] if the key doesn't exists
    #   @raise [Couchbase::Error::KeyExists] on CAS mismatch
    #   @raise [ArgumentError] when passing the block in synchronous mode
    #   @raise [Couchbase::Error::Timeout] if timeout interval for observe
    #     exceeds
    #
    #   @example Replacing missing key
    #     c.replace("foo", "baz")  #=> will raise Couchbase::Error::NotFound: failed to store value (key="foo", error=0x0d)
    #
    #   @example Ensure that the key will be persisted at least on the one node
    #     c.replace("foo", "bar", :observe => {:persisted => 1})
    #
    def replace(key, value, options = {})
      sync_block_error if !async? && block_given?

      future = if options[:ttl].nil?
                 client.replace(key.to_s, dump(value))
               else
                 client.replace(key.to_s, options[:ttl], dump(value))
               end

      if cas = future_cas(future)
        cas
      else
        raise Couchbase::Error::NotFound.new
      end
    end

    # Append this object to the existing object
    #
    # @since 1.0.0
    #
    # @note This operation is kind of data-aware from server point of view.
    #   This mean that the server treats value as binary stream and just
    #   perform concatenation, therefore it won't work with +:marshal+ and
    #   +:document+ formats, because of lack of knowledge how to merge values
    #   in these formats. See {Bucket#cas} for workaround.
    #
    # @overload append(key, value, options = {})
    #   @param key [String, Symbol] Key used to reference the value.
    #   @param value [Object] Value to be stored
    #   @param options [Hash] Options for operation.
    #   @option options [Fixnum] :cas The CAS value for an object. This value
    #     created on the server and is guaranteed to be unique for each value of
    #     a given key. This value is used to provide simple optimistic
    #     concurrency control when multiple clients or threads try to update an
    #     item simultaneously.
    #   @option options [Symbol] :format (self.default_format) The
    #     representation for storing the value in the bucket. For more info see
    #     {Bucket#default_format}.
    #   @option options [Hash] :observe Apply persistence condition before
    #     returning result. When this option specified the library will observe
    #     given condition. See {Bucket#observe_and_wait}.
    #
    #   @return [Fixnum] The CAS value of the object.
    #
    #   @raise [Couchbase::Error::Connect] if connection closed (see {Bucket#reconnect})
    #   @raise [Couchbase::Error::KeyExists] on CAS mismatch
    #   @raise [Couchbase::Error::NotStored] if the key doesn't exist
    #   @raise [ArgumentError] when passing the block in synchronous mode
    #   @raise [Couchbase::Error::Timeout] if timeout interval for observe
    #     exceeds
    #
    #   @example Simple append
    #     c.set("foo", "aaa")
    #     c.append("foo", "bbb")
    #     c.get("foo")           #=> "aaabbb"
    #
    #   @example Implementing sets using append
    #     def set_add(key, *values)
    #       encoded = values.flatten.map{|v| "+#{v} "}.join
    #       append(key, encoded)
    #     end
    #
    #     def set_remove(key, *values)
    #       encoded = values.flatten.map{|v| "-#{v} "}.join
    #       append(key, encoded)
    #     end
    #
    #     def set_get(key)
    #       encoded = get(key)
    #       ret = Set.new
    #       encoded.split(' ').each do |v|
    #         op, val = v[0], v[1..-1]
    #         case op
    #         when "-"
    #           ret.delete(val)
    #         when "+"
    #           ret.add(val)
    #         end
    #       end
    #       ret
    #     end
    #
    #   @example Using optimistic locking. The operation will fail on CAS mismatch
    #     ver = c.set("foo", "aaa")
    #     c.append("foo", "bbb", :cas => ver)
    #
    #   @example Ensure that the key will be persisted at least on the one node
    #     c.append("foo", "bar", :observe => {:persisted => 1})
    #
    def append(key, value)
      sync_block_error if !async? && block_given?
      if cas = java_append(validate_key(key), value)
        cas
      else
        raise Couchbase::Error::NotFound.new
      end
    end

    # Prepend this object to the existing object
    #
    # @since 1.0.0
    #
    # @note This operation is kind of data-aware from server point of view.
    #   This mean that the server treats value as binary stream and just
    #   perform concatenation, therefore it won't work with +:marshal+ and
    #   +:document+ formats, because of lack of knowledge how to merge values
    #   in these formats. See {Bucket#cas} for workaround.
    #
    # @overload prepend(key, value, options = {})
    #   @param key [String, Symbol] Key used to reference the value.
    #   @param value [Object] Value to be stored
    #   @param options [Hash] Options for operation.
    #   @option options [Fixnum] :cas The CAS value for an object. This value
    #     created on the server and is guaranteed to be unique for each value of
    #     a given key. This value is used to provide simple optimistic
    #     concurrency control when multiple clients or threads try to update an
    #     item simultaneously.
    #   @option options [Symbol] :format (self.default_format) The
    #     representation for storing the value in the bucket. For more info see
    #     {Bucket#default_format}.
    #   @option options [Hash] :observe Apply persistence condition before
    #     returning result. When this option specified the library will observe
    #     given condition. See {Bucket#observe_and_wait}.
    #
    #   @raise [Couchbase::Error::Connect] if connection closed (see {Bucket#reconnect})
    #   @raise [Couchbase::Error::KeyExists] on CAS mismatch
    #   @raise [Couchbase::Error::NotStored] if the key doesn't exist
    #   @raise [ArgumentError] when passing the block in synchronous mode
    #   @raise [Couchbase::Error::Timeout] if timeout interval for observe
    #     exceeds
    #
    #   @example Simple prepend example
    #     c.set("foo", "aaa")
    #     c.prepend("foo", "bbb")
    #     c.get("foo")           #=> "bbbaaa"
    #
    #   @example Using explicit format option
    #     c.default_format       #=> :document
    #     c.set("foo", {"y" => "z"})
    #     c.prepend("foo", '[', :format => :plain)
    #     c.append("foo", ', {"z": "y"}]', :format => :plain)
    #     c.get("foo")           #=> [{"y"=>"z"}, {"z"=>"y"}]
    #
    #   @example Using optimistic locking. The operation will fail on CAS mismatch
    #     ver = c.set("foo", "aaa")
    #     c.prepend("foo", "bbb", :cas => ver)
    #
    #   @example Ensure that the key will be persisted at least on the one node
    #     c.prepend("foo", "bar", :observe => {:persisted => 1})
    #
    def prepend(*args)
      sync_block_error if !async? && block_given?
    end

    private

    def store_args_parser(key, value, options)
      key = key.to_str if key.respond_to?(:to_str)
      ttl = options[:ttl] || default_ttl

      op  = case key
            when String, Symbol
              :single
            when Hash
              raise TypeError.new if !value.nil?
              :multi
            else
              raise TypeError.new
            end

      [op, key, value, ttl]
    end

    def set_single(key, value, ttl, options = {}, &block)
      if options[:cas]
        cas_response = client.cas(key.to_s, options[:cas], ttl, dump(value))
        if cas_response.to_s == 'OK'
          get(key, extended: true)[2]
        else
          raise Couchbase::Error::KeyExists.new
        end
      else
        if cas = client_set(key, value, ttl)
          cas
        else
          raise Couchbase::Error::KeyExists.new
        end
      end
    end

    def add_single(key, value, ttl, options = {})
      if cas = client_add(key, value, ttl)
        cas
      else
        raise Couchbase::Error::KeyExists.new
      end
    end

    # TODO:
    def set_multi(keys)
      {}.tap do |results|
        keys.each_pair do |key, value|
          results[key] = client_set(key, value, default_ttl)
        end
      end
    end

    def add_multi(keys)
      {}.tap do |results|
        keys.each_pair do |key, value|
          results[key] = client_add(key, value, default_ttl)
        end
      end
    end

    def client_append(key, value)
      future = client.append(key.to_s, dump(value))
      future_cas(future)
    end

    def client_set(key, value, ttl)
      future = client.set(key.to_s, ttl, dump(value))
      future_cas(future)
    end

    def client_add(key, value, ttl)
      future = client.add(key.to_s, ttl, dump(value))
      future_cas(future)
    end

  end

end
