module Couchbase

  class DesignDocFormatError < Error::Base; end

  class DesignDoc

    java_import com.couchbase.client.java.view.DesignDocument
    java_import com.couchbase.client.java.view.DefaultView

    def initialize(name, design_doc)
      @name  = name
      @views = java.util.ArrayList.new
      design_doc.each_pair do |view_name, view|
        if view.key?(:reduce)
          @views.add DefaultView.create(view_name.to_s, view[:map], view[:reduce])
        else
          @views.add DefaultView.create(view_name.to_s, view[:map])
        end
      end
    rescue => e
      raise DesignDocFormatError, e
    end

    def create
      DesignDocument.create(@name, @views)
    end
  end
end
