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
require 'minitest/autorun'
require 'couchbase'

require 'socket'
require 'open-uri'
require 'ostruct'

require 'pry'

# Surpress connection logging
# java_import java.lang.System
# java_import java.util.logging.Logger
# java_import java.util.logging.Level

# properties = System.getProperties
# properties.put("net.spy.log.LoggerImpl", "net.spy.memcached.compat.log.Log4JLogger")
# System.setProperties(properties)

# Logger.getLogger('net.spy.memcached').setLevel(Level::SEVERE)
# Logger.getLogger('com.couchbase.client').setLevel(Level::SEVERE)
# Logger.getLogger('com.couchbase.client.vbucket').setLevel(Level::SEVERE)

# $stderr = StringIO.new

class CouchbaseServer
  attr_accessor :host, :port, :num_nodes, :buckets_spec

  def real?
    true
  end

  def initialize(params = {})
    @host, @port = ENV['COUCHBASE_SERVER'].split(':')
    @port = @port.to_i

    if @host.nil? || @host.empty? || @port == 0
      raise ArgumentError, 'Check COUCHBASE_SERVER variable. It should be hostname:port'
    end

    @config = MultiJson.load(open("http://#{@host}:#{@port}/pools/default"))
    @num_nodes = @config['nodes'].size
    @buckets_spec = params[:buckets_spec] || 'default:'  # "default:,protected:secret,cache::memcache"
  end

  def start
    # flush all buckets
    @buckets_spec.split(',') do |bucket|
      name, password, _ = bucket.split(':')
      connection = Couchbase.new(:hostname => @host,
                                 :port => @port,
                                 :username => name,
                                 :bucket => name,
                                 :password => password)
      connection.flush
    end
  end
  def stop; end
end

require "#{File.dirname(__FILE__)}/CouchbaseMock.jar"

class CouchbaseMock
  attr_accessor :host, :port, :num_nodes, :buckets_spec, :num_vbuckets

  def real?
    false
  end

  def initialize(params = {})
    @host = 'localhost'
    @port = 8091
    @num_nodes = 1
    @num_vbuckets = 4096
    @buckets_spec = 'default:'  # "default:,protected:secret,cache::memcache"
    params.each do |key, value|
      send("#{key}=", value)
    end
    yield self if block_given?
    if @num_vbuckets < 1 || (@num_vbuckets & (@num_vbuckets - 1) != 0)
      raise ArgumentError, 'Number of vbuckets should be a power of two and greater than zero'
    end
    @mock = Java::OrgCouchbaseMock::CouchbaseMock.new(@host, @port, @num_nodes, @num_vbuckets, @buckets_spec)
  end

  def start
    @mock.start
    @mock.waitForStartup
  end

  def stop
    @mock.stop
  end
end

def start_mock(params = {})
  mock = nil
  if ENV['COUCHBASE_SERVER']
    mock = CouchbaseServer.new(params)
    if (params[:port] && mock.port != params[:port]) ||
      (params[:host] && mock.host != params[:host]) ||
      mock.buckets_spec != 'default:'
      skip("Unable to configure real cluster. Requested config is: #{params.inspect}")
    end
  else
    mock = CouchbaseMock.new(params)
  end
  mock.start
  mock
end

def stop_mock(mock)
  # assert(mock)
  mock.stop
end

$mock = start_mock

Minitest.after_run do
  Couchbase.disconnect
  stop_mock($mock)
end

class Minitest::Test

  def cb
    Couchbase.bucket
  end

  def with_configs(configs = {})
    configs = Couchbase::Bucket::DEFAULT_OPTIONS.merge(configs)
    if configs[:host].nil?
      configs[:host] = configs[:hostname]
    end
    yield OpenStruct.new(configs)
  end

  def uniq_id(*suffixes)
    test_id = [caller.first[/.*[` ](.*)'/, 1], suffixes].compact.join("_")
    @ids ||= {}
    @ids[test_id] ||= Time.now.to_f
    [test_id, @ids[test_id]].join("_")
  end

end
