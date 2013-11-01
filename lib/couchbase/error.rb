
module Couchbase
  module Error
    class Base < Exception
      attr_accessor :cas, :error, :inner_exception, :key, :operation, :status

      def to_s
        if inner_exception
          inner_exception.to_s
        else
          super
        end
      end
    end

    class Connect < Base
    end

    class Auth < Base
    end

    class Connect < Base
    end

    class NotFound < Base
    end

    class Invalid < Base
    end

    class KeyExists < Base
    end

    class ValueFormat < Base
    end

    class TemporaryFail < Base
    end
  end
end
