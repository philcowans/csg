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

    def [](i)
      @coordinates[i]
    end

    def classify(boundary)
      boundary_length = Math.sqrt(Vertex.dot(boundary, boundary))
      d = Vertex.dot(@coordinates, boundary) / boundary_length
      if d > boundary_length + 0.01
        :positive
      elsif d < boundary_length - 0.01
        :negative
      else
        :on_boundary
      end
    end
  end

  class Edge
    class << self
      def dot(a,b)
        a[0]*b[0] + a[1]*b[1] + a[2]*b[2]
      end
    end

    attr_reader :vertices

    def initialize(v1, v2)
      @vertices = [v1, v2]
    end

    def classify(boundary)
      classes = @vertices.map{|v| v.classify(boundary)}
      if classes.all?{|c| c == :on_boundary}
        :on_boundary
      elsif !(classes.any?{|c| c == :negative})
        :positive
      elsif !(classes.any?{|c| c == :positive})
        :negative
      else
        :both
      end
    end

    def faces(all_cells)
      all_faces = all_cells.map{|c| c.faces}.flatten.uniq
      all_faces.select{|f| f.edges.include?(self)}
    end

    def partition(boundary)
      classes = @vertices.map{|v| v.classify(boundary)}

      f = (Edge.dot(boundary, boundary) - Edge.dot(@vertices[0], boundary)) /
        (Edge.dot(@vertices[1], boundary) - Edge.dot(@vertices[0], boundary))
      additional_vertex = Vertex.new((1-f) * @vertices[0][0] + f * @vertices[1][0],
                                 (1-f) * @vertices[0][1] + f * @vertices[1][1],
                                 (1-f) * @vertices[0][2] + f * @vertices[1][2])
      if (classes[0] == :positive) && (classes[1] == :negative)
        {
          :positive => Edge.new(@vertices[0], additional_vertex),
          :negative => Edge.new(additional_vertex, @vertices[1])
        }
      elsif (classes[0] == :negative) && (classes[1] == :positive)
        {
          :positive => Edge.new(additional_vertex, @vertices[1]),
          :negative => Edge.new(@vertices[0], additional_vertex)
        }
      else
        raise 'Attempting to partition edge which doesn\'t span boundary'
      end
    end
  end

  class Face
    attr_reader :edges

    def initialize(edges)
      @edges = edges
    end

    def boundary?(all_cells)
#      return false unless @edges.all?{|e| e.vertices.all?{|v| v.coordinates.all?{|c| c.abs < 100.0}}}

#      return true
      adjacent_cells = cells(all_cells)
#      puts adjacent_cells.map{|l| l.label}.inspect
      if adjacent_cells.size == 1
        # (we're on the boundary of the universe)
        adjacent_cells.first.label
      elsif adjacent_cells.size == 2
        adjacent_cells.first.label != adjacent_cells.last.label
      else
        raise "We somehow had an edge with #{adjacent_cells.size} adjacent cells, should be 1 or 2"
      end
    end

    def cells(all_cells)
      all_cells.select{|c| c.faces.include?(self)}
    end

    def classify(boundary)
      classes = @edges.map{|e| e.classify(boundary)}
      if classes.all?{|c| c == :on_boundary}
        :on_boundary
      elsif classes.all?{|c| (c == :positive) || (c == :on_boundary)}
        :positive
      elsif classes.all?{|c| (c == :negative) || (c == :on_boundary)}
        :negative
      else
        :both
      end
    end

    def partition(boundary, all_cells)
      edges_with_classes = @edges.map{|e| [e, e.classify(boundary)]}
      edges_with_classes.select{|e| e.last == :both}.map{|e| e.first}.each do |e|
        result = e.partition(boundary)
        @edges.delete(e) # FIXME - is it important to preserve ordering here?
        @edges << result[:positive]
        @edges << result[:negative]
        e.faces(all_cells).each do |f|
          f.replace_edge(e, [result[:positive], result[:negative]]) unless e == self
        end
      end
      edges_with_classes = @edges.map{|e| [e, e.classify(boundary)]}
      positive = edges_with_classes.select{|e| e.last == :positive}.map{|e| e.first}
      negative = edges_with_classes.select{|e| e.last == :negative}.map{|e| e.first}
      if positive.empty? || negative.empty?
        raise 'Attempting to partition face which doesn\'t span boundary'
      else
        vertices_with_classes = positive.map{|e| e.vertices}.flatten.uniq.map{|v| [v, v.classify(boundary)]}
        boundary_vertices = vertices_with_classes.select{|v| v.last == :on_boundary}.map{|v| v.first}
        raise 'Expected exactly 2 boundary vertices' unless boundary_vertices.size == 2
        boundary_face = Edge.new(boundary_vertices[0], boundary_vertices[1])
        positive << boundary_face
        negative << boundary_face

        {
          :positive => Face.new(positive),
          :negative => Face.new(negative)
        }
      end
    end

    def polygons
      vertices = @edges.map{|e| e.vertices}
      return [] if vertices.size < 3
      v = vertices.first.first
      ordered_vertices = []
      while v
        ordered_vertices << v
        if vertices.empty?
          v = nil
        else
          anchor_edge = vertices.select{|e| (e.first == v) || (e.last == v)}.first
          if anchor_edge.first == v
            v = anchor_edge.last
          else
            v = anchor_edge.first
          end
          vertices.delete(anchor_edge)
        end
      end
      p = []
      while ordered_vertices.size >= 3
        p << [ordered_vertices[0].coordinates, ordered_vertices[1].coordinates, ordered_vertices[2].coordinates]
        ordered_vertices.delete_at(1)
      end
      p
    end

    def replace_edge(old, new)
      @edges.delete(old)
      new.each{|e| @edges << e}
    end
  end

  class Cell
    attr_accessor :label
    attr_reader :faces

    def initialize(faces)
      @faces = faces
      @label = false
    end

    def partition(boundary, all_cells)
      faces_with_classes = @faces.map{|f| [f, f.classify(boundary)]}
      faces_with_classes.select{|f| f.last == :both}.map{|f| f.first}.each do |f|
        result = f.partition(boundary, all_cells)
        @faces.delete(f)
        @faces << result[:positive]
        @faces << result[:negative]
        f.cells(all_cells).each do |c|
          c.replace_face(f, [result[:positive], result[:negative]]) unless c == self
        end
      end
      faces_with_classes = @faces.map{|f| [f, f.classify(boundary)]}
      # Silently ignore attempts to partition along an existing face
      return :positive_non_partition unless faces_with_classes.any?{|f| f.last == :negative}
      return :negative_non_partition unless faces_with_classes.any?{|f| f.last == :positive}
      positive = faces_with_classes.select{|f| f.last == :positive}.map{|f| f.first}
      negative = faces_with_classes.select{|f| f.last == :negative}.map{|f| f.first}

      edges_with_classes = positive.map{|f| f.edges}.flatten.uniq.map{|e| [e, e.classify(boundary)]}
      boundary_edges = edges_with_classes.select{|e| e.last == :on_boundary}.map{|e| e.first}
      boundary_face = Face.new(boundary_edges)
      positive << boundary_face
      negative << boundary_face

      {
        :positive => Cell.new(positive),
        :negative => Cell.new(negative)
      }
    end

    def replace_face(old, new)
      @faces.delete(old)
      new.each{|f| @faces << f}
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
#    puts @cells.size
#    puts @cells.map{|c| c.label}.inspect
    faces = @cells.map{|c| c.faces}.flatten.uniq
    p = faces.select{|f| f.boundary?(@cells)}.map{|f| f.polygons}.flatten(1)
#    p.select{|i| i.all?{|v| v.all?{|c| c.abs < 100.0}}}
  end

  private

  def recursive_partition_by_bsp_tree(node, cell)
    if node.boundary
      result = cell.partition(node.position, @cells)
      if result == :negative_non_partition
        recursive_partition_by_bsp_tree(node.negative, cell)
      elsif result == :positive_non_partition
        recursive_partition_by_bsp_tree(node.positive, cell)
      elsif result.nil?
      else
        @cells.delete(cell)
        @cells << result[:positive]
        @cells << result[:negative]
        recursive_partition_by_bsp_tree(node.positive, result[:positive])
        recursive_partition_by_bsp_tree(node.negative, result[:negative])
      end
    else
    #  puts "Assignment: #{node.label.inspect}"
      cell.label = node.label
    end
  end
end
