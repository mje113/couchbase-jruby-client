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
  module Store

    STORE_OP_METHODS = {
      set:     -> client, key, value, ttl, transcoder { client.set(key, ttl, value, transcoder) },
      add:     -> client, key, value, ttl, transcoder { client.add(key, ttl, value, transcoder) },
      replace: -> client, key, value, ttl, transcoder { client.replace(key, ttl, value, transcoder) },
      append:  -> client, key, value, ttl, transcoder { client.append(key, value) },
      prepend: -> client, key, value, ttl, transcoder { client.prepend(key, value) }
    }.freeze

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
      if async?
        if block_given?
          async_set(key, value, options, &Proc.new)
        else
          async_set(key, value, options)
        end
      else
        sync_block_error if block_given?
        store_op(:set, key, value, options)
      end
    end

    def async_set(key, value, options, &block)
      async_store_op(:set, key, value, options, &block)
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
      if async?
        if block_given?
          async_add(key, value, options, &Proc.new)
        else
          async_add(key, value, options)
        end
      else
        sync_block_error if block_given?
        store_op(:add, key, value, options)
      end
    end

    def async_add(key, value, options, &block)
      async_store_op(:add, key, value, options, &block)
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
      if async?
        if block_given?
          async_replace(key, value, options, &Proc.new)
        else
          async_replace(key, value, options)
        end
      else
        sync_block_error if block_given?
        store_op(:replace, key, value, options)
      end
    end

    def async_replace(key, value, options, &block)
      async_store_op(:replace, key, value, options, &block)
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
      sync_block_error if block_given?
      store_op(:append, key, value)
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
    def prepend(key, value)
      sync_block_error if block_given?
      store_op(:prepend, key, value)
    end

    private

    def store_args_parser(key, value, options)
      key = key.to_str if key.respond_to?(:to_str)
      ttl = options.delete(:ttl) || default_ttl
      transcoder = @transcoders[options.delete(:format)] || @transcoder

      [key, value, ttl, transcoder]
    end

    def store_op(op, key, value, options = {})
      key, value, ttl, transcoder = store_args_parser(key, value, options)

      if key.is_a?(String) || key.is_a?(Symbol)
        store_by_string(op, key.to_s, value, ttl, transcoder, options)
      elsif key.is_a?(Hash)
        store_by_hash(op, key, value)
      else
        fail TypeError.new
      end
    end

    def store_by_string(op, key, value, ttl, transcoder, options)
      if options[:cas] && op == :set
        client_cas(key, value, ttl, options[:cas], transcoder)
      else
        future = client_store_op(op, key, value, ttl, transcoder)
        if cas = future_cas(future)
          cas
        else
          fail_store_op(op)
        end
      end
    end

    def store_by_hash(op, key, value)
      fail TypeError.new if !value.nil?
      multi_op(op, key)
    end

    def async_store_op(op, key, value, options, &block)
      key, value, ttl, transcoder = store_args_parser(key, value, options)
      future = client_store_op(op, key, value, ttl, transcoder)
      register_future(future, { op: op }, &block)
    end

    def multi_op(op, keys)
      {}.tap do |results|
        keys.each_pair do |key, value|
          results[key] = client.send(op, key, default_ttl, value)
        end
      end
    end

    def client_store_op(op, key, value, ttl, transcoder)
      STORE_OP_METHODS[op].call(self.client, key, value, ttl, transcoder)
    end

    def client_cas(key, value, ttl, cas, transcoder)
      cas_response = client.cas(key, cas, ttl, value, transcoder)
      if cas_response.to_s == 'OK'
        get(key, extended: true)[2]
      else
        raise Couchbase::Error::KeyExists.new
      end
    end

    def fail_store_op(op)
      case op
      when :replace
        fail Couchbase::Error::NotFound
      when :append, :prepend
        fail Couchbase::Error::NotStored
      else
        fail Couchbase::Error::KeyExists
      end
    end

  end

end
