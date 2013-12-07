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

require 'couchbase/operations/touch'
require 'couchbase/operations/store'
require 'couchbase/operations/get'
require 'couchbase/operations/fetch'
require 'couchbase/operations/delete'
require 'couchbase/operations/unlock'
require 'couchbase/operations/arithmetic'
require 'couchbase/operations/stats'
require 'couchbase/operations/design_docs'
require 'couchbase/operations/utils'

module Couchbase
  module Operations

    def self.included(klass)
      klass.send(:include, Store)
      klass.send(:include, Get)
      klass.send(:include, Fetch)
      klass.send(:include, Touch)
      klass.send(:include, Delete)
      klass.send(:include, Unlock)
      klass.send(:include, Arithmetic)
      klass.send(:include, Stats)
      klass.send(:include, DesignDocs)
      klass.send(:include, Utils)
    end
  end
end

