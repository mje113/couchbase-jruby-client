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
    def touch(*args)
      key, ttl, options = expand_touch_args(args)

      case key
      when String, Symbol
        success = client_touch(key, ttl)
        not_found_error(!success, options)
        success
      when Hash
        multi_touch_hash(key, options)
      when Array
        multi_touch_array(key, options)
      end
    end

    def async_touch(key, ttl, &block)
      register_future(client.touch(key, ttl), { op: :touch }, &block)
    end

    private

    def expand_touch_args(args)
      options = extract_options_hash(args)
      ttl = options[:ttl] || if args.size > 1 && args.last.respond_to?(:to_int?)
                               args.pop
                             else
                               default_ttl
                             end
      key = args.size > 1 ? args : args.pop

      [key, ttl, options]
    end

    def multi_touch_hash(keys, options = {})
      {}.tap do |results|
        keys.each_pair do |key, ttl|
          results[key] = client_touch(key, ttl)
        end
      end
    end

    def multi_touch_array(keys, options = {})
      ttl = options[:ttl] || default_ttl

      {}.tap do |results|
        keys.each do |key|
          results[key] = client_touch(key, ttl)
        end
      end
    end

    def client_touch(key, ttl, options = {})
      client.touch(key, ttl).get
    end

  end
end
