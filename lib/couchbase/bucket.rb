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

  class Bucket

    include Couchbase::Operations

    attr_reader :bucket

    def initialize(bucket)
      @bucket = bucket
      @transcoder = Transcoders::MultiJsonTranscoder.new
    end

    def async
      @bucket.async
    end

    def save_design_doc(name, design_doc, development = false)
      design_doc = DesignDoc.new(name, design_doc)
      @bucket.bucket_manager.upsert_design_document(design_doc.create, development)
    end
  end
end
