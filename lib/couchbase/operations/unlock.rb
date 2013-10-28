module Couchbase::Operations
  module Touch

    # Unlock key
    #
    # @since 1.2.0
    #
    # The +unlock+ method allow you to unlock key once locked by {Bucket#get}
    # with +:lock+ option.
    #
    # @overload unlock(key, options = {})
    #   @param key [String, Symbol] Key used to reference the value.
    #   @param options [Hash] Options for operation.
    #   @option options [Fixnum] :cas The CAS value must match the current one
    #     from the storage.
    #   @option options [true, false] :quiet (self.quiet) If set to +true+, the
    #     operation won't raise error for missing key, it will return +nil+.
    #
    #   @return [true, false] +true+ if the operation was successful and +false+
    #     otherwise.
    #
    #   @raise [Couchbase::Error::Connect] if connection closed (see {Bucket#reconnect})
    #
    #   @raise [ArgumentError] when passing the block in synchronous mode
    #
    #   @raise [Couchbase::Error::NotFound] if key(s) not found in the storage
    #
    #   @raise [Couchbase::Error::TemporaryFail] if either the key wasn't
    #      locked or given CAS value doesn't match to actual in the storage
    #
    #   @example Unlock the single key
    #     val, _, cas = c.get("foo", :lock => true, :extended => true)
    #     c.unlock("foo", :cas => cas)
    #
    # @overload unlock(keys)
    #   @param keys [Hash] The Hash where keys represent the keys in the
    #     database, values -- the CAS for corresponding key.
    #
    #   @yieldparam ret [Result] the result of operation for each key in
    #     asynchronous mode (valid attributes: +error+, +operation+, +key+).
    #
    #   @return [Hash] Mapping keys to result of unlock operation (+true+ if the
    #     operation was successful and +false+ otherwise)
    #
    #   @example Unlock several keys
    #     c.unlock("foo" => cas1, :bar => cas2) #=> {"foo" => true, "bar" => true}
    #
    #   @example Unlock several values in async mode
    #     c.run do
    #       c.unlock("foo" => 10, :bar => 20) do |ret|
    #          ret.operation   #=> :unlock
    #          ret.success?    #=> true
    #          ret.key         #=> "foo" and "bar" in separate calls
    #       end
    #     end
    #

    def unlock(key, options = {})
      
    end

  end
end

__END__

/*
 * Unlock key
 *
 * @since 1.2.0
 *
 * The +unlock+ method allow you to unlock key once locked by {Bucket#get}
 * with +:lock+ option.
 *
 * @overload unlock(key, options = {})
 *   @param key [String, Symbol] Key used to reference the value.
 *   @param options [Hash] Options for operation.
 *   @option options [Fixnum] :cas The CAS value must match the current one
 *     from the storage.
 *   @option options [true, false] :quiet (self.quiet) If set to +true+, the
 *     operation won't raise error for missing key, it will return +nil+.
 *
 *   @return [true, false] +true+ if the operation was successful and +false+
 *     otherwise.
 *
 *   @raise [Couchbase::Error::Connect] if connection closed (see {Bucket#reconnect})
 *
 *   @raise [ArgumentError] when passing the block in synchronous mode
 *
 *   @raise [Couchbase::Error::NotFound] if key(s) not found in the storage
 *
 *   @raise [Couchbase::Error::TemporaryFail] if either the key wasn't
 *      locked or given CAS value doesn't match to actual in the storage
 *
 *   @example Unlock the single key
 *     val, _, cas = c.get("foo", :lock => true, :extended => true)
 *     c.unlock("foo", :cas => cas)
 *
 * @overload unlock(keys)
 *   @param keys [Hash] The Hash where keys represent the keys in the
 *     database, values -- the CAS for corresponding key.
 *
 *   @yieldparam ret [Result] the result of operation for each key in
 *     asynchronous mode (valid attributes: +error+, +operation+, +key+).
 *
 *   @return [Hash] Mapping keys to result of unlock operation (+true+ if the
 *     operation was successful and +false+ otherwise)
 *
 *   @example Unlock several keys
 *     c.unlock("foo" => cas1, :bar => cas2) #=> {"foo" => true, "bar" => true}
 *
 *   @example Unlock several values in async mode
 *     c.run do
 *       c.unlock("foo" => 10, :bar => 20) do |ret|
 *          ret.operation   #=> :unlock
 *          ret.success?    #=> true
 *          ret.key         #=> "foo" and "bar" in separate calls
 *       end
 *     end
 *
 */
   VALUE
cb_bucket_unlock(int argc, VALUE *argv, VALUE self)
{
    struct cb_bucket_st *bucket = DATA_PTR(self);
    struct cb_context_st *ctx;
    VALUE rv, proc, exc;
    lcb_error_t err;
    struct cb_params_st params;

    if (!cb_bucket_connected_bang(bucket, cb_sym_unlock)) {
        return Qnil;
    }

    memset(&params, 0, sizeof(struct cb_params_st));
    rb_scan_args(argc, argv, "0*&", &params.args, &proc);
    if (!bucket->async && proc != Qnil) {
        rb_raise(rb_eArgError, "synchronous mode doesn't support callbacks");
    }
    rb_funcall(params.args, cb_id_flatten_bang, 0);
    params.type = cb_cmd_unlock;
    params.bucket = bucket;
    cb_params_build(&params);
    ctx = cb_context_alloc_common(bucket, proc, params.cmd.unlock.num);
    ctx->quiet = params.cmd.unlock.quiet;
    err = lcb_unlock(bucket->handle, (const void *)ctx,
            params.cmd.unlock.num, params.cmd.unlock.ptr);
    cb_params_destroy(&params);
    exc = cb_check_error(err, "failed to schedule unlock request", Qnil);
    if (exc != Qnil) {
        cb_context_free(ctx);
        rb_exc_raise(exc);
    }
    bucket->nbytes += params.npayload;
    if (bucket->async) {
        cb_maybe_do_loop(bucket);
        return Qnil;
    } else {
        if (ctx->nqueries > 0) {
            /* we have some operations pending */
            lcb_wait(bucket->handle);
        }
        exc = ctx->exception;
        rv = ctx->rv;
        cb_context_free(ctx);
        if (exc != Qnil) {
            rb_exc_raise(exc);
        }
        exc = bucket->exception;
        if (exc != Qnil) {
            bucket->exception = Qnil;
            rb_exc_raise(exc);
        }
        if (params.cmd.unlock.num > 1) {
            return rv;  /* return as a hash {key => true, ...} */
        } else {
            VALUE vv = Qnil;
            rb_hash_foreach(rv, cb_first_value_i, (VALUE)&vv);
            return vv;
        }
    }
}

