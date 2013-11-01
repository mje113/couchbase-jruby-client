# Author:: Couchbase <info@couchbase.com>
# Copyright:: 2013 Couchbase, Inc.
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

require 'multi_json'

module Couchbase

  module Transcoder

    module Compat
      def self.enable!
        @disabled = false
      end

      def self.disable!
        @disabled = true
      end

      def self.enabled?
        !@disabled
      end

      def self.guess_and_load(blob, flags, options = {})
        case flags & Bucket::FMT_MASK
        when Bucket::FMT_DOCUMENT
          MultiJson.load(blob)
        when Bucket::FMT_MARSHAL
          ::Marshal.load(blob)
        when Bucket::FMT_PLAIN
          blob
        else
          raise ArgumentError, "unexpected flags (0x%02x)" % flags
        end
      end
    end

    class Base < Java::NetSpyMemcachedTranscoders::SerializingTranscoder
    end

    class Document < Base

      def decode(d)
        data = case decoded = super
               when String
                 decoded
               else
                 decoded.getData.to_s
               end

        MultiJson.load(data)
      rescue MultiJson::LoadError
        ::Marshal.load(data)
      end

      def encode(o)
        super MultiJson.dump(o)
      rescue ArgumentError => e
        ex = Couchbase::Error::ValueFormat.new
        ex.inner_exception = e
        fail ex
      end
    end

    class Marshal < Base

      def decode(d)
        ::Marshal.load super.getData.to_s
      end

      def encode(o)
        super ::Marshal.dump(o)
      end
    end

    class Plain < Base

      def decode(d)
        super
      end

      def encode(o)
        super(o.to_str)
      rescue NoMethodError
        raise Couchbase::Error::ValueFormat
      end
    end

  end

end
