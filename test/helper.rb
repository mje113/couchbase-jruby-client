# Author:: Couchbase <info@couchbase.com>
# Copyright:: 2011, 2012 Couchbase, Inc.
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

gem 'minitest'
require 'coveralls'
Coveralls.wear!
require 'minitest'
require 'minitest/autorun'
require 'pry'
require 'couchbase'
require 'ostruct'

module Minitest
  class Test

    def uniq_id(*suffixes)
      test_id = [caller.first[/.*[` ](.*)'/, 1], suffixes].compact.join('_')
      @ids ||= {}
      @ids[test_id] ||= Time.now.to_f
      [test_id, @ids[test_id]].join('_')
    end
  end
end
