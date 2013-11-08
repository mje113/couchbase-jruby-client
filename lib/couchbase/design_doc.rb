module Couchbase
  class DesignDoc

    def initialize(bucket, doc)
      @all_views = {}
      @bucket    = bucket
      @name      = doc.name
      @views     = doc.views
      @spatial   = doc.spatial_views
      @views.each   { |view| @all_views[view.name] = "#{@name}/_view/#{view.name}" }
      @spatial.each { |view| @all_views[view.name] = "#{@name}/_spatial/#{view.name}" }
    end

    def method_missing(meth, *args)
      if path = @all_views[meth.to_s]
        View.new(@bucket, path, *args)
      else
        super
      end
    end

    def respond_to_missing?(meth, *args)
      @all_views[meth.to_s] || super
    end

    # The list of views defined or empty array
    #
    # @since 1.2.1
    #
    # @return [Array<View>]
    attr_accessor :views

    # The list of spatial views defined or empty array
    #
    # @since 1.2.1
    #
    # @return [Array<View>]
    attr_accessor :spatial

    # Check if the document has views defines
    #
    # @since 1.2.1
    #
    # @see DesignDoc#views
    #
    # @return [true, false] +true+ if the document have views
    def has_views?
      !@views.empty?
    end

    def inspect
      desc = "#<#{self.class.name}:#{self.object_id}"
      [:@id, :@views, :@spatial].each do |iv|
        desc << " #{iv}=#{instance_variable_get(iv).inspect}"
      end
      desc << ">"
      desc
    end

  end
end