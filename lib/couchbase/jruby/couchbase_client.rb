module Couchbase
  module Jruby
    class CouchbaseClient < Java::ComCouchbaseClient::CouchbaseClient

      # Futures
      %w(add set append asyncCAS asyncDecr asyncGet asyncGetAndTouch asyncGetBulk
        asyncGets asyncIncr delete flush prepend replace set touch).each do |op|
        define_method(op) do |*|
          super
        end
      end

      def get(*)
        super
      end

      VALUE_OPS = %w(

      ).freeze
    end
  end
end
