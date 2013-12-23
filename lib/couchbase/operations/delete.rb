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
    def delete(*args)
      key, cas, options = expand_delete_args(args)

      if key.respond_to?(:to_ary)
        delete_multi(key, options)
      else
        delete_single(key, cas, options)
      end
    end

    def async_delete(*args, &block)
      key, cas, options = expand_delete_args(args)

      future = client.delete(key)
      register_future(future, { op: :delete }, &block)
    end

    private

    def expand_delete_args(args)
      key, options = expand_get_args(args)

      if key.respond_to?(:to_str)
        [key, options[:cas], options]
      else
        cas = if key.size > 1 &&
                 key.last.respond_to?(:to_int)
                key.pop
              else
                nil
              end

        key = key.size == 1 ? key.first : key

        [key, cas, options]
      end
    end

    def delete_single(key, cas, options)
      future = cas.nil? ? client.delete(key) : client.delete(key, cas)
      cas = future_cas(future)
      not_found_error(!cas, options)
      cas
    end

    def delete_multi(keys, options = {})
      {}.tap do |results|
        keys.each do |key|
          results[key] = delete_single(key, nil, options)
        end
      end
    end
  end
end
