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

    # module Compat
    #   def self.enable!
    #     @disabled = false
    #   end

    #   def self.disable!
    #     @disabled = true
    #   end

    #   def self.enabled?
    #     !@disabled
    #   end

    #   def self.guess_and_load(blob, flags, options = {})
    #     case flags & Bucket::FMT_MASK
    #     when Bucket::FMT_DOCUMENT
    #       MultiJson.load(blob)
    #     when Bucket::FMT_MARSHAL
    #       ::Marshal.load(blob)
    #     when Bucket::FMT_PLAIN
    #       blob
    #     else
    #       raise ArgumentError, "unexpected flags (0x%02x)" % flags
    #     end
    #   end
    # end

    module Document
      def self.dump(obj)
        MultiJson.dump(obj)
      end

      def self.load(blob)
        MultiJson.load(blob)
      end
    end

    module Marshal
      def self.dump(obj)
        ::Marshal.dump(obj)
      end

      def self.load(blob)
        ::Marshal.load(blob)
      end
    end

    module Plain
      def self.dump(obj)
        obj
      end

      def self.load(blob)
        blob
      end
    end

  end

end
