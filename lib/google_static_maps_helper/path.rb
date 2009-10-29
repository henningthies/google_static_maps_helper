module GoogleStaticMapsHelper
  #
  # A Path is used to draw things in the map, either lines or Polygons.
  # It is build up of points and if a fill color is set you'll get a Polygon.
  #
  class Path
    include Enumerable

    OPTIONAL_OPTIONS = [:weight, :color, :fillcolor]

    attr_accessor :points, *OPTIONAL_OPTIONS

    #
    # Creates a new Path which you can push points on to to make up lines or polygons
    #
    # The following options are available, for more information see the 
    # Google API documentation[http://code.google.com/apis/maps/documentation/staticmaps/#Paths].
    #
    # <tt>:weight</tt>::    The weight is the thickness of the line, defaults to 5
    # <tt>:color</tt>::     The color of the border can either be a textual representation like red, green, blue, black etc
    #                       or as a 24-bit (0xAABBCC) or 32-bit hex value (0xAABBCCDD). When 32-bit values are
    #                       given the two last bits will represent the alpha transparency value.
    # <tt>:fillcolor</tt>:: With the fill color set you'll get a polygon in the map. The color value can be the same
    #                       as described in the <tt>:color</tt>. When used, the static map will automatically create
    #                       a closed shape.
    # <tt>:points</tt>::    An array of points. You can mix objects responding to lng and lat, and a Hash with lng and lat keys.
    #
    def initialize(options = {})
      @points = []
      options.each_pair {|k, v| send("#{k}=", v)}
    end

    #
    # Returns a string representation of this Path
    # Used by the Map when building the URL
    #
    def url_params # :nodoc:
      raise BuildDataMissing, "Need at least 2 points to create a path!" unless can_build?
      out = 'path='
     
      path_params = OPTIONAL_OPTIONS.inject([]) do |path_params, attribute|
        value = send(attribute)
        path_params << "#{attribute}:#{URI.escape(value.to_s)}" unless value.nil?
        path_params
      end.join('|')

      out += "#{path_params}|" unless path_params.empty?

      out += inject([]) do |point_params, point|
        point_params << point.to_url
      end.join('|')
    end

  
    #
    # Sets the points of this Path.
    # 
    # *WARNING* Using this method will clear out any points which might be set.
    #
    def points=(array)
      raise ArgumentError unless array.is_a? Array
      @points = []
      array.each {|point| self << point}
    end

    def each
      @points.each {|p| yield p}
    end

    def length
      @points.length
    end

    def empty?
      length == 0
    end

    #
    # Pushes a new point into the Path
    #
    # A point might be a Hash which has lng and lat as keys, or an object responding to
    # lng and lat. Any points pushed in will be converted internally to a Location
    # object.
    #
    def <<(point)
      @points << ensure_point_is_location_object(point)
      @points.uniq!
      self
    end


    private
    #
    # Extracts the lng and lat values from incomming point and creates a new Location
    # object from it.
    #
    def ensure_point_is_location_object(point)
      return point if point.instance_of? Location
      Location.new(point)
    end
    
    # 
    # Do we have enough points to build a path?
    #
    def can_build?
      length > 1
    end
  end
end
