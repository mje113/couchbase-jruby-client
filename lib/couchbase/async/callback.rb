module Couchbase
  module Async
    class Callback
      include Java::NetSpyMemcachedInternal::OperationCompletionListener

      def initialize(operation, &callback)
        @operation, @callback = operation, callback
      end

      def onComplete(future)
        result = Couchbase::Result.new(operation: @operation, future: future)
        @callback.call(result)
      rescue Exception => e
        result.error = e
        return result
      end
    end
  end
end
