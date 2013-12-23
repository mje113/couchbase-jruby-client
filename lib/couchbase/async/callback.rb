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
  module Async
    class Callback
      include Java::NetSpyMemcachedInternal::OperationCompletionListener
      include Java::NetSpyMemcachedInternal::GetCompletionListener

      def initialize(params, &callback)
        @params   = params
        @callback = callback
      end

      def onComplete(future)
        result = Couchbase::Result.new(@params.merge(future: future))
        @callback.call(result)
      rescue Exception => e
        result.error = e
        return result
      end
    end
  end
end
