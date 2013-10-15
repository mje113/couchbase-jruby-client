module Couchbase::Operations
  module Stats

    def stats(statname = nil)
      sync_block_error if !async? && block_given?
      stats = if statname.nil?
                client.getStats
              else
                client.getStats(statname)
              end

      stats.first.last.to_hash
    end

  end
end
