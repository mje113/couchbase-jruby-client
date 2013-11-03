module Couchbase::Operations
  module Stats

    def stats(statname = nil)
      sync_block_error if !async? && block_given?
      stats = if statname.nil?
                client.getStats
              else
                client.getStats(statname)
              end

      stats = stats.to_hash

      {}.tap do |hash|
        stats.each_pair do |node, values|
          node_value = node.to_s
          values.each_pair do |stat, value|
            hash[stat] ||= {}
            hash[stat][node_value] = value
          end
        end
      end
    end

  end
end
