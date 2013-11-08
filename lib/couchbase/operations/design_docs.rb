# Author:: Mike Evans <mike@urlgonomics.com>
# Copyright:: 2013 Urlgonomics LLC.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Couchbase::Operations
  module DesignDocs

    java_import com.couchbase.client.protocol.views.DesignDocument
    java_import com.couchbase.client.protocol.views.ViewDesign

    class DesignDocAccess
      def initialize(bucket)
        @bucket = bucket
      end

      def [](name)
        doc = @bucket.client.getDesignDocument(name)
        Couchbase::DesignDoc.new(@bucket, doc)
      rescue Java::ComCouchbaseClientProtocolViews::InvalidViewException
        nil
      end
    end

    # Fetch design docs stored in current bucket
    #
    # @since 1.2.0
    #
    # @return [Hash]
    def design_docs
      DesignDocAccess.new(self)
    end

    # Update or create design doc with supplied views
    #
    # @since 1.2.0
    #
    # @param [Hash, IO, String] data The source object containing JSON
    #   encoded design document. It must have +_id+ key set, this key
    #   should start with +_design/+.
    #
    # @return [true, false]
    def save_design_doc(data)
      attrs = case data
              when String
                MultiJson.load(data)
              when IO
                MultiJson.load(data.read)
              when Hash
                data
              else
                raise ArgumentError, "Document should be Hash, String or IO instance"
              end
      
      id = attrs.delete('_id').to_s.split('/')[1]

      design_doc = DesignDocument.new(id)

      attrs['views'].each_pair do |view, functions| 
        view_design = if functions['reduce']
                        ViewDesign.new(view, functions['map'], functions['reduce'])
                      else
                        ViewDesign.new(view, functions['map'])
                      end
        design_doc.getViews.add(view_design)
      end

      client.createDesignDoc(design_doc)
    end

    # Delete design doc with given id and revision.
    #
    # @since 1.2.0
    #
    # @param [String] id Design document id. It might have '_design/'
    #   prefix.
    #
    # @param [String] rev Document revision. It uses latest revision if
    #   +rev+ parameter is nil.
    #
    # @return [true, false]
    def delete_design_doc(id, rev = nil)
      client.deleteDesignDoc(id)
    end

  end
end
