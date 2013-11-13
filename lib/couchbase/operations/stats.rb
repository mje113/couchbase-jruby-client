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
  module Stats

    def stats(statname = nil)
      sync_block_error if !async? && block_given?
      stats = if statname.nil?
                client.getStats
              else
                client.getStats(statname)
              end

      stats = stats.to_hash

      {}.tap do |hash|
        stats.each_pair do |node, values|
          node_value = node.to_s
          values.each_pair do |stat, value|
            hash[stat] ||= {}
            hash[stat][node_value] = value
          end
        end
      end
    end

  end
end
