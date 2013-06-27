class BoundaryRep
  class Vertex
    class << self
      def dot(a,b)
        a[0]*b[0] + a[1]*b[1] + a[2]*b[2]
      end
    end

    attr_reader :coordinates

    def initialize(x, y, z)
      @coordinates = [x, y, z]
    end

    def classify(boundary)
      boundary_length = Math.sqrt(Vertex.dot(boundary, boundary))
      d = Vertex.dot(@coordinates, boundary) / boundary_length
      if d > boundary_length
        :positive
      elsif d < boundary_length
        :negative
      else
        :on_boundary
      end
    end
  end

  class Edge
    attr_reader :vertices

    def initialize(v1, v2)
      @vertices = [v1, v2]
    end

    def partition(boundary)
      classes = @vertices.map{|v| v.classify(boundary)}
    end
  end

  class Face
    def initialize(edges)
      @edges = edges
    end

    def partition(boundary)
      positive = []
      negative = []
      added_vertices = []

      @edges.each do |edge|
        p, n, a = edge.partition(boundary)
        positive << p
        negative << n
        added_vertices << a unless a.nil?
      end

      if added_vertices.empty?
        closure_edge = nil
      else
        unless added_vertices.size == 2
          raise "Expected either 0 or 2 vertices on boundary, got #{added_vertices.size}"
        end
        closure_edge = Edge.new(added_vertices[0], added_vertices[1])
        positive << closure_edge
        negative << closure_edge
      end

      # TODO: Need to handle case where vertices lie on boundary (TESTS!)
      # TODO: Actually need to update edge lists, including for other faces sharing an edge

      [positive, negative, closure_edge]
    end

    def polygons
      vertices = @edges.map{|e| e.vertices}.flatten.uniq
      p = []
      while vertices.size >= 3
        p << [vertices[0].coordinates, vertices[1].coordinates, vertices[2].coordinates]
        vertices.delete_at(1)
      end
      p
    end
  end

  class Cell
    def initialize(faces)
      @faces = faces
    end

    def partition(boundary)
      positive = []
      negative = []
      added_edges = []

      @faces.each do |face|
        p, n, a = face.partition(boundary)
        positive << p
        negative << n
        added_edges << a unless a.nil?
      end

      unless added_edges.empty?
        closure_face = Face.new(added_edges)
        positive << closure_face
        negative << closure_face
      end

      if negative.empty? or positive.empty?
        {
          :delete => [],
          :add => nil
        }
      else
        {
          :delete => [self],
          :add => {
            :positive => Cell.new(positive),
            :negative => Cell.new(negative)
          }
        }
      end
    end

    def polygons
      @faces.map{|f| f.polygons}.flatten(1)
    end
  end

  def initialize(universe_size)
    v_ppp = Vertex.new(universe_size, universe_size, universe_size)
    v_ppm = Vertex.new(universe_size, universe_size, -universe_size)
    v_pmp = Vertex.new(universe_size, -universe_size, universe_size)
    v_pmm = Vertex.new(universe_size, -universe_size, -universe_size)
    v_mpp = Vertex.new(-universe_size, universe_size, universe_size)
    v_mpm = Vertex.new(-universe_size, universe_size, -universe_size)
    v_mmp = Vertex.new(-universe_size, -universe_size, universe_size)
    v_mmm = Vertex.new(-universe_size, -universe_size, -universe_size)

    e_xpp = Edge.new(v_ppp, v_mpp)
    e_xpm = Edge.new(v_ppm, v_mpm)
    e_xmp = Edge.new(v_pmp, v_mmp)
    e_xmm = Edge.new(v_pmm, v_mmm)
    e_pxp = Edge.new(v_ppp, v_pmp)
    e_pxm = Edge.new(v_ppm, v_pmm)
    e_mxp = Edge.new(v_mpp, v_mmp)
    e_mxm = Edge.new(v_mpm, v_mmm)
    e_ppx = Edge.new(v_ppp, v_ppm)
    e_pmx = Edge.new(v_pmp, v_pmm)
    e_mpx = Edge.new(v_mpp, v_mpm)
    e_mmx = Edge.new(v_mmp, v_mmm)

    f_xp = Face.new([e_pxp, e_pxm, e_ppx, e_pmx])
    f_xm = Face.new([e_mxp, e_mxm, e_mpx, e_mmx])
    f_yp = Face.new([e_xpp, e_xpm, e_ppx, e_mpx])
    f_ym = Face.new([e_xmp, e_xmm, e_pmx, e_mmx])
    f_zp = Face.new([e_xpp, e_xmp, e_pxp, e_mxp])
    f_zm = Face.new([e_xpm, e_xmm, e_pxm, e_mxm])

    @cells = [Cell.new([f_xp, f_xm, f_yp, f_ym, f_zp, f_zm])]
  end

  def partition_by_bsp_tree!(root)
    recursive_partition_by_bsp_tree(root, @cells[0])
  end

  def polygons
    @cells.map{|c| c.polygons}.flatten(1)
  end

  private

  def recursive_partition_by_bsp_tree(node, cell)
    if node.boundary
      result = cell.partition(node.position)
      result[:delete].each{|c| @cells.delete(c)}
      if result[:add]
        @cells << result[:add][:positive]
        @cells << result[:add][:negative]
        recursive_partition_by_bsp_tree(node.positive, result[:add][:positive])
        recursive_partition_by_bsp_tree(node.negative, result[:add][:negative])
      end
    end
  end
end
