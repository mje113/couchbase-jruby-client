module Couchbase
  module Async
    class Queue

      def initialize(bucket)
        @bucket  = bucket
        @futures = []
      end

      def add_future(future, options, &block)
        @futures << [ future, options, block ]
      end

      def join
        while future = @futures.pop
          begin
            future, options, callback = future
            future.get
            result = Couchbase::Result.new({ bucket: @bucket, future: future }.merge(options))
            callback.call(result) unless callback.nil?
          end
        end
      end
    end
  end
end
