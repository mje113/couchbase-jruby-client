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

module Couchbase
  class Result

    attr_accessor :error

    def initialize(attrs = {})
      @bucket    = attrs[:bucket]
      @key       = attrs[:key]
      @operation = attrs[:op]
      @future    = attrs[:future]
    end

    def operation
      @operation
    end

    def success?
      @future.get
    end

    def error
      @error
    end

    def key
      @key || @future.getKey
    end

    def value
      @future.get
    rescue MultiJson::LoadError
      nil
    end

    def cas
      @future.getCas if @future.respond_to?(:getCas)
    end

    def node

    end
  end
end
