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

require File.join(File.dirname(__FILE__), 'setup')

class TestViewRow < Minitest::Test

  def setup
    return unless $mock.real?

    cb.save_design_doc(design_doc)
    { baltimore: 'md' , philadelphia: 'pa', pittsburgh: 'pa' }.each_pair do |city, state|
      cb.set(city, { type: 'city', city: city, state: state })
    end
  end

  def view
    @view ||= Couchbase::View.new(cb, '_design/cities/_view/by_state')
  end

  def test_doc
    skip unless $mock.real?
    assert result = view.fetch(include_docs: true, stale: false).first

    data = result.data

    assert_instance_of Java::ComCouchbaseClientProtocolViews::ViewRowWithDocs, data

    assert_equal({'id' => result.id}, data.doc['meta'])
    assert_equal({'type' => result['type'], 'city' => result['city'], 'state' => result['state']}, data.doc['value'])
  end

  def test_doc_for_ViewRowNoDocs_objects
    skip unless $mock.real?
    assert result = view.fetch(include_docs: false, stale: false).first

    data = result.data

    assert_instance_of Java::ComCouchbaseClientProtocolViews::ViewRowNoDocs, data
    assert_equal({ id: result.id, key: data.key, value: data.value }, data.doc)
  end

  def design_doc
    {
      '_id'      => '_design/cities',
      'language' => 'javascript',
      'views' => {
        'by_state' => {
          'map' => <<-JS
            function (doc, meta) {
              if (doc.type && doc.type == 'city')
                emit(meta.id, doc.state);
            }
          JS
        }
      }
    }
  end

end
