require 'couchbase/operations/touch'
require 'couchbase/operations/store'
require 'couchbase/operations/get'
require 'couchbase/operations/delete'
require 'couchbase/operations/arithmetic'
require 'couchbase/operations/stats'
require 'couchbase/operations/utils'

module Couchbase
  module Operations

    def self.included(klass)
      klass.send(:include, Store)
      klass.send(:include, Get)
      klass.send(:include, Touch)
      klass.send(:include, Delete)
      klass.send(:include, Arithmetic)
      klass.send(:include, Stats)
      klass.send(:include, Utils)
    end
  end
end

