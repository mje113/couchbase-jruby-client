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
  module Arithmetic

    # Increment the value of an existing numeric key
    #
    # @since 1.0.0
    #
    # The increment methods allow you to increase a given stored integer
    # value. These are the incremental equivalent of the decrement operations
    # and work on the same basis; updating the value of a key if it can be
    # parsed to an integer. The update operation occurs on the server and is
    # provided at the protocol level. This simplifies what would otherwise be a
    # two-stage get and set operation.
    #
    # @note that server values stored and transmitted as unsigned numbers,
    #   therefore if you try to store negative number and then increment or
    #   decrement it will cause overflow. (see "Integer overflow" example
    #   below)
    #
    # @overload incr(key, delta = 1, options = {})
    #   @param key [String, Symbol] Key used to reference the value.
    #   @param delta [Fixnum] Integer (up to 64 bits) value to increment
    #   @param options [Hash] Options for operation.
    #   @option options [true, false] :create (false) If set to +true+, it will
    #     initialize the key with zero value and zero flags (use +:initial+
    #     option to set another initial value). Note: it won't increment the
    #     missing value.
    #   @option options [Fixnum] :initial (0) Integer (up to 64 bits) value for
    #     missing key initialization. This option imply +:create+ option is
    #     +true+.
    #   @option options [Fixnum] :ttl (self.default_ttl) Expiry time for key.
    #     Values larger than 30*24*60*60 seconds (30 days) are interpreted as
    #     absolute times (from the epoch). This option ignored for existent
    #     keys.
    #   @option options [true, false] :extended (false) If set to +true+, the
    #     operation will return tuple +[value, cas]+, otherwise (by default) it
    #     returns just value.
    #
    #   @yieldparam ret [Result] the result of operation in asynchronous mode
    #     (valid attributes: +error+, +operation+, +key+, +value+, +cas+).
    #
    #   @return [Fixnum] the actual value of the key.
    #
    #   @raise [Couchbase::Error::NotFound] if key is missing and +:create+
    #     option isn't +true+.
    #
    #   @raise [Couchbase::Error::DeltaBadval] if the key contains non-numeric
    #     value
    #
    #   @raise [Couchbase::Error::Connect] if connection closed (see {Bucket#reconnect})
    #
    #   @raise [ArgumentError] when passing the block in synchronous mode
    #
    #   @example Increment key by one
    #     c.incr("foo")
    #
    #   @example Increment key by 50
    #     c.incr("foo", 50)
    #
    #   @example Increment key by one <b>OR</b> initialize with zero
    #     c.incr("foo", :create => true)   #=> will return old+1 or 0
    #
    #   @example Increment key by one <b>OR</b> initialize with three
    #     c.incr("foo", 50, :initial => 3) #=> will return old+50 or 3
    #
    #   @example Increment key and get its CAS value
    #     val, cas = c.incr("foo", :extended => true)
    #
    #   @example Integer overflow
    #     c.set("foo", -100)
    #     c.get("foo")           #=> -100
    #     c.incr("foo")          #=> 18446744073709551517
    #
    #   @example Asynchronous invocation
    #     c.run do
    #       c.incr("foo") do |ret|
    #         ret.operation   #=> :increment
    #         ret.success?    #=> true
    #         ret.key         #=> "foo"
    #         ret.value
    #         ret.cas
    #       end
    #     end
    #
    def incr(*args)
      do_arithmetic(:incr, *args)
    end
    alias_method :increment, :incr

    # Decrement the value of an existing numeric key
    #
    # @since 1.0.0
    #
    # The decrement methods reduce the value of a given key if the
    # corresponding value can be parsed to an integer value. These operations
    # are provided at a protocol level to eliminate the need to get, update,
    # and reset a simple integer value in the database. It supports the use of
    # an explicit offset value that will be used to reduce the stored value in
    # the database.
    #
    # @note that server values stored and transmitted as unsigned numbers,
    #   therefore if you try to decrement negative or zero key, you will always
    #   get zero.
    #
    # @overload decr(key, delta = 1, options = {})
    #   @param key [String, Symbol] Key used to reference the value.
    #   @param delta [Fixnum] Integer (up to 64 bits) value to decrement
    #   @param options [Hash] Options for operation.
    #   @option options [true, false] :create (false) If set to +true+, it will
    #     initialize the key with zero value and zero flags (use +:initial+
    #     option to set another initial value). Note: it won't decrement the
    #     missing value.
    #   @option options [Fixnum] :initial (0) Integer (up to 64 bits) value for
    #     missing key initialization. This option imply +:create+ option is
    #     +true+.
    #   @option options [Fixnum] :ttl (self.default_ttl) Expiry time for key.
    #     Values larger than 30*24*60*60 seconds (30 days) are interpreted as
    #     absolute times (from the epoch). This option ignored for existent
    #     keys.
    #   @option options [true, false] :extended (false) If set to +true+, the
    #     operation will return tuple +[value, cas]+, otherwise (by default) it
    #     returns just value.
    #
    #   @yieldparam ret [Result] the result of operation in asynchronous mode
    #     (valid attributes: +error+, +operation+, +key+, +value+, +cas+).
    #
    #   @return [Fixnum] the actual value of the key.
    #
    #   @raise [Couchbase::Error::NotFound] if key is missing and +:create+
    #     option isn't +true+.
    #
    #   @raise [Couchbase::Error::DeltaBadval] if the key contains non-numeric
    #     value
    #
    #   @raise [Couchbase::Error::Connect] if connection closed (see {Bucket#reconnect})
    #
    #   @raise [ArgumentError] when passing the block in synchronous mode
    #
    #   @example Decrement key by one
    #     c.decr("foo")
    #
    #   @example Decrement key by 50
    #     c.decr("foo", 50)
    #
    #   @example Decrement key by one <b>OR</b> initialize with zero
    #     c.decr("foo", :create => true)   #=> will return old-1 or 0
    #
    #   @example Decrement key by one <b>OR</b> initialize with three
    #     c.decr("foo", 50, :initial => 3) #=> will return old-50 or 3
    #
    #   @example Decrement key and get its CAS value
    #     val, cas = c.decr("foo", :extended => true)
    #
    #   @example Decrementing zero
    #     c.set("foo", 0)
    #     c.decrement("foo", 100500)   #=> 0
    #
    #   @example Decrementing negative value
    #     c.set("foo", -100)
    #     c.decrement("foo", 100500)   #=> 0
    #
    #   @example Asynchronous invocation
    #     c.run do
    #       c.decr("foo") do |ret|
    #         ret.operation   #=> :decrement
    #         ret.success?    #=> true
    #         ret.key         #=> "foo"
    #         ret.value
    #         ret.cas
    #       end
    #     end
    #
    def decr(*args)
      do_arithmetic(:decr, *args)
    end
    alias_method :decrement, :decr

    private

    def do_arithmetic(op, *args)
      key, delta, options = expand_arithmetic_args(args)

      case key
      when String, Symbol
        single_arithmetic(op, key, delta, options)
      when Array, Hash
        multi_arithmetic(op, key, delta)
      else
        raise # something
      end
    end

    def expand_arithmetic_args(args)
      options = if args.size > 1 && args.last.respond_to?(:to_h)
                  args.pop
                else
                  {}
                end

      delta   = if args.size > 1 && args.last.respond_to?(:to_int)
                  args.pop
                else
                  options[:delta] || 1
                end

      key = args.size == 1 ? args.first : args

      [validate_key(key), delta, options]
    end

    def single_arithmetic(op, key, delta, options = {})
      result = case op
               when :incr
                 client.incr(key, delta)
               when :decr
                 client.decr(key, delta)
               end

      set_default_arithmetic_or_raise(key, result, options)
    end

    def set_default_arithmetic_or_raise(key, result, options)
      return result if result > 0

      if options[:initial] || options[:create] || set_default_arithmetic_init?
        value = if options[:initial]
                  options[:initial]
                elsif options[:create]
                  0
                else
                  default_arithmetic_init_int
                end

        set(key, value, options) && value
      else
        not_found_error(true)
      end
    end

    def set_default_arithmetic_init?
      default_arithmetic_init == true ||
        default_arithmetic_init.respond_to?(:to_int) &&
          default_arithmetic_init > 0
    end

    def default_arithmetic_init_int
      default_arithmetic_init == true ? 0 : default_arithmetic_init
    end

    def multi_arithmetic(op, keys, delta)
      {}.tap do |results|
        if keys.respond_to?(:each_pair)
          keys.each_pair do |k, v|
            results[k] = single_arithmetic(op, k, v)
          end
        else
          keys.each do |k|
            results[k] = single_arithmetic(op, k, delta)
          end
        end
      end
    end

    # def java_async_incr(key, delta)
    #   client.asyncIncr(key, delta)
    # end

    # def java_async_decr(key, delta)
    #   client.asyncDecr(key, delta)
    # end

  end
end
