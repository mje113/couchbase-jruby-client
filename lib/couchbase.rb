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

fail 'This gem is only compatible with JRuby.' unless RUBY_PLATFORM =~ /java/

require 'jars/rxjava-1.0.8'
require 'jars/rxjruby-0.0.1'
require 'jars/couchbase-core-io-1.1.4'
require 'jars/couchbase-java-client-2.1.4'
require 'rx/lang/jruby/interop'
require 'couchbase/version'
require 'couchbase/error'
require 'couchbase/document'
require 'couchbase/operations'
require 'couchbase/cluster'
require 'couchbase/bucket'
require 'couchbase/view'
require 'couchbase/design_doc'
require 'couchbase/configuration'
require 'couchbase/view'
require 'multi_json'

at_exit do
  Couchbase.disconnect if Couchbase.connected?
end

# Couchbase jruby client
module Couchbase

  class ConfigurationError < Error::Base; end

  module_function

  @conn = Configuration.new

  def connection_options=(options)
    fail ConfigurationError, 'Cannot reconfigure an already connected cluster.' if connected?
    @conn = Configuration.new(options)
  end

  def connected?
    @cluster
  end

  def disconnect
    @cluster.disconnect if @cluster
    @buckets = nil
  end

  def cluster
    @cluster ||= Cluster.new(@conn.hosts)
  end

  def bucket(name = nil)
    name ||= :default
    buckets[name.to_sym]
  end

  def buckets
    @buckets ||= begin
      {}.tap do |buckets|
        @conn.buckets.each do |bucket|
          buckets[bucket.name.to_sym] = cluster.open_bucket(bucket.name, bucket.password)
        end
      end
    end
  end
end
