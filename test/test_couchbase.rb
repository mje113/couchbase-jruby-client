require 'helper'

class TestCouchbase < Minitest::Test

  def test_couchbase_module
    assert Couchbase.is_a? Module
  end

  def test_couchbase_init
    assert_instance_of Module, Couchbase
  end

  def test_cluster_access
    assert_instance_of Couchbase::Cluster, Couchbase.cluster
  end

  def test_bucket_access
    assert_instance_of Couchbase::Bucket, Couchbase.bucket
  end

  def test_connection_status
    Couchbase.bucket
    assert Couchbase.connected?
  end

  def test_configuration_error
    Couchbase.bucket
    assert_raises Couchbase::ConfigurationError do
      Couchbase.connection_options = {}
    end
  end

  def test_multiple_bukets
    assert_instance_of Couchbase::Bucket, Couchbase.buckets[:default]
    assert_instance_of Couchbase::Bucket, Couchbase.bucket(:default)
  end
end
