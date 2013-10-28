require 'couchbase/async/callback'
require 'couchbase/async/queue'

module Couchbase
  module Async

    def async?
      !!async
    end

    def async
      Thread.current[:bucket_async] ||= @async
    end

    def async=(val)
      Thread.current[:bucket_async] = val
    end

    def running?
      !!running
    end

    def running
      Thread.current[:bucket_running] ||= false
    end

    def running=(val)
      Thread.current[:bucket_running] = val
    end

    def async_queue
      Thread.current[:bucket_async_queue] ||= Couchbase::Async::Queue.new(self)
    end

    def end_async_queue
      Thread.current[:bucket_async_queue] = nil
    end

    public

    # Run the event loop.
    #
    # @since 1.0.0
    #
    # @param [Hash] options The options for operation for connection
    # @option options [Fixnum] :send_threshold (0) if the internal command
    #   buffer will exceeds this value, then the library will start network
    #   interaction and block the current thread until all scheduled commands
    #   will be completed.
    #
    # @yieldparam [Bucket] bucket the bucket instance
    #
    # @example Use block to run the loop
    #   c = Couchbase.new
    #   c.run do
    #     c.get("foo") {|ret| puts ret.value}
    #   end
    #
    # @example Use lambda to run the loop
    #   c = Couchbase.new
    #   operations = lambda do |c|
    #     c.get("foo") {|ret| puts ret.value}
    #   end
    #   c.run(&operations)
    #
    # @example Use threshold to send out commands automatically
    #   c = Couchbase.connect
    #   sent = 0
    #   c.run(:send_threshold => 8192) do  # 8Kb
    #     c.set("foo1", "x" * 100) {|r| sent += 1}
    #     # 128 bytes buffered, sent is 0 now
    #     c.set("foo2", "x" * 10000) {|r| sent += 1}
    #     # 10028 bytes added, sent is 2 now
    #     c.set("foo3", "x" * 100) {|r| sent += 1}
    #   end
    #   # all commands were executed and sent is 3 now
    #
    # @example Use {Couchbase::Bucket#run} without block for async connection
    #   c = Couchbase.new(:async => true)
    #   c.run      # ensure that instance connected
    #   c.set("foo", "bar"){|r| puts r.cas}
    #   c.run
    #
    # @return [nil]
    #
    # @raise [Couchbase::Error::Connect] if connection closed (see {Bucket#reconnect})
    #
    def run(options = {})
      do_async_setup(block_given?)
      yield(self)
      async_queue.join

      # TODO: deal with exceptions
      nil
    ensure
      do_async_ensure
    end

    def run_async(options = {})
      do_async_setup(block_given?)
      yield(self)
      nil
    ensure
      do_async_ensure
    end

    private

    def do_async_setup(block_given)
      raise LocalJumpError.new('block required for async run') unless block_given
      # TODO: check for connection
      raise Error::Invalid.new('nested #run') if running?
      # TOOD: deal with thresholds

      self.async   = true
      self.running = true
    end

    def do_async_ensure
      self.async   = false
      self.running = false
      end_async_queue
    end

    def register_future(future, options, &block)
      if async_queue
        async_queue.add_future(future, options, &block)
      else
        register_callback(future, &block)
      end
      future
    end

    def register_callback(future, &block)
      callback = Couchbase::Callback.new(:set, &block)
      future.addListener(callback)
    end

  end
end
