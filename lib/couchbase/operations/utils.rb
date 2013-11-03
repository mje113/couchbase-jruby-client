module Couchbase::Operations
  module Utils

    private

    def validate_key(key)
      if key_prefix
        "#{key_prefix}key"
      else
        key.to_s
      end
    end

    def extract_options_hash(args)
      if args.size > 1 && args.last.respond_to?(:to_hash)
        args.pop
      else
        {}
      end
    end

    def sync_block_error
      raise ArgumentError, "synchronous mode doesn't support callbacks"
    end

    def not_found_error(error, options = {})
      if error
        if options.key?(:quiet)
          raise Couchbase::Error::NotFound.new if !options[:quiet]
        elsif !quiet?
          raise Couchbase::Error::NotFound.new
        end
      end
    end

    def future_cas(future)
      future.get && future.getCas
    rescue Java::JavaLang::UnsupportedOperationException
      # TODO: don't return fake cas
      1
    end

  end
end
