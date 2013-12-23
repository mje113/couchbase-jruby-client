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
