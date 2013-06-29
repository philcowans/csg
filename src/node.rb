class Node
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



  attr_accessor :label
  attr_reader :boundary, :name, :negative, :parent, :parent_positive, :position, :positive

  UNIVERSE_SIZE = 10000.0

  def initialize(label, parent = nil, parent_positive = nil, name = '', cell = nil, all_cells = nil)
    @name = name
    @label = label
    @positive = nil
    @negative = nil
    @position = nil
    @boundary = nil
    @parent = parent
    @parent_positive = parent_positive

    if cell == nil
      v_ppp = Vertex.new(UNIVERSE_SIZE, UNIVERSE_SIZE, UNIVERSE_SIZE)
      v_ppm = Vertex.new(UNIVERSE_SIZE, UNIVERSE_SIZE, -UNIVERSE_SIZE)
      v_pmp = Vertex.new(UNIVERSE_SIZE, -UNIVERSE_SIZE, UNIVERSE_SIZE)
      v_pmm = Vertex.new(UNIVERSE_SIZE, -UNIVERSE_SIZE, -UNIVERSE_SIZE)
      v_mpp = Vertex.new(-UNIVERSE_SIZE, UNIVERSE_SIZE, UNIVERSE_SIZE)
      v_mpm = Vertex.new(-UNIVERSE_SIZE, UNIVERSE_SIZE, -UNIVERSE_SIZE)
      v_mmp = Vertex.new(-UNIVERSE_SIZE, -UNIVERSE_SIZE, UNIVERSE_SIZE)
      v_mmm = Vertex.new(-UNIVERSE_SIZE, -UNIVERSE_SIZE, -UNIVERSE_SIZE)

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

      @cell = Cell.new([f_xp, f_xm, f_yp, f_ym, f_zp, f_zm])
    else
      @cell = cell
    end
    @all_cells = all_cells || [@cell]
  end

  def dot(a, b)
    (a[0] * b[0]) + (a[1] * b[1]) + (a[2] * b[2])
  end

  def interior_leaf_count
    if @position
      @positive.interior_leaf_count + @negative.interior_leaf_count
    else
      @label ? 1 : 0
    end
  end

  def intersect_with_universe
    if (@position[1] == 0) && (@position[2] == 0)
      basis_1 = [0.0, 1.0, 0.0]
    else
      basis_1 = [1.0, 0.0, 0.0]
    end

    position_length = Math.sqrt(dot(@position, @position))

    basis_1_overlap = dot(basis_1, @position) / position_length
    basis_1 = [
      basis_1[0] - basis_1_overlap * @position[0],
      basis_1[1] - basis_1_overlap * @position[1],
      basis_1[2] - basis_1_overlap * @position[2]
    ]
    basis_1_norm = Math.sqrt(dot(basis_1, basis_1))

    basis_2 = [
      @position[1] * basis_1[2] - @position[2] * basis_1[1],
      @position[2] * basis_1[0] - @position[0] * basis_1[2],
      @position[0] * basis_1[1] - @position[1] * basis_1[0]
     ]
    basis_2_norm = Math.sqrt(dot(basis_2, basis_2))

    vertices = []
    vertices << [
      @position[0] + 10 * UNIVERSE_SIZE * basis_1[0] / basis_1_norm,
      @position[1] + 10 * UNIVERSE_SIZE * basis_1[1] / basis_1_norm,
      @position[2] + 10 * UNIVERSE_SIZE * basis_1[2] / basis_1_norm
    ]
    vertices << [
      @position[0] + 10 * UNIVERSE_SIZE * basis_2[0] / basis_2_norm,
      @position[1] + 10 * UNIVERSE_SIZE * basis_2[1] / basis_2_norm,
      @position[2] + 10 * UNIVERSE_SIZE * basis_2[2] / basis_2_norm
    ]
    vertices << [
      @position[0] - 10 * UNIVERSE_SIZE * basis_1[0] / basis_1_norm,
      @position[1] - 10 * UNIVERSE_SIZE * basis_1[1] / basis_1_norm,
      @position[2] - 10 * UNIVERSE_SIZE * basis_1[2] / basis_1_norm
    ]
    vertices << [
      @position[0] - 10 * UNIVERSE_SIZE * basis_2[0] / basis_2_norm,
      @position[1] - 10 * UNIVERSE_SIZE * basis_2[1] / basis_2_norm,
      @position[2] - 10 * UNIVERSE_SIZE * basis_2[2] / basis_2_norm
    ]

    positive, negative = partition_polygon(vertices, [UNIVERSE_SIZE, 0.0, 0.0])
    positive, negative = partition_polygon(negative, [-UNIVERSE_SIZE, 0.0, 0.0])
    positive, negative = partition_polygon(negative, [0.0, UNIVERSE_SIZE, 0.0])
    positive, negative = partition_polygon(negative, [0.0, -UNIVERSE_SIZE, 0.0])
    positive, negative = partition_polygon(negative, [0.0, 0.0, UNIVERSE_SIZE])
    positive, negative = partition_polygon(negative, [0.0, 0.0, -UNIVERSE_SIZE])
    negative
  end

  def leaf_count
    if @position.nil?
      1
    else
      @positive.leaf_count + @negative.leaf_count
    end
  end

  def on_positive_side?(p, position = nil)
    position ||= @position
    position_length = Math.sqrt(dot(position, position))
    d = dot(p, position) / position_length
    if d > position_length + 0.01
      true
    elsif d < position_length - 0.01
      false
    else
      nil # Returns nil to indicate
    end
  end

  def partition(other)
    [
      recursive_partition_for_positive(other),
      recursive_partition_for_negative(other)
    ]
  end

  def partition_polygon(vertices, position = nil)
    position ||= @position
    positive_vertices = []
    negative_vertices = []
    labeled_vertices = vertices.map{|v| [v, on_positive_side?(v, position)]}
    labeled_vertices.each_with_index do |v, i|
      next_vertex = labeled_vertices[(i+1) % labeled_vertices.size]
      if v.last.nil?
        positive_vertices << v.first
        negative_vertices << v.first
      else
        positive_vertices << v.first if v.last == true
        negative_vertices << v.first if v.last == false
        if (!(next_vertex.last.nil?)) && (next_vertex.last != v.last)
          f = (dot(position, position) - dot(v.first, position)) /
            (dot(next_vertex.first, position) - dot(v.first, position))
          intersect = [
            (1-f) * v.first[0] + f * next_vertex.first[0],
            (1-f) * v.first[1] + f * next_vertex.first[1],
            (1-f) * v.first[2] + f * next_vertex.first[2]
          ]
          positive_vertices << intersect
          negative_vertices << intersect
        end
      end
    end
    [positive_vertices, negative_vertices]
  end

  def recursively_copy_into(other_node, subtract)
#    puts "subtract = #{subtract}"
    if @position.nil?
#      puts "Labeling (intersection of #{other_node.name} and #{@name}): #{other_node.label}, #{@label}"
      if subtract
#        puts "subtracting"
        other_node.label = other_node.label && (!@label)
      else
        other_node.label = other_node.label || @label
      end
    else
      positive, negative = other_node.split(@position, other_node.label, other_node.label)
      @positive.recursively_copy_into(positive, subtract) if positive
      @negative.recursively_copy_into(negative, subtract) if negative
    end
  end

  def recursive_partition_for_negative(other)
    return self unless @position
    # Naming convention, first element is our position relative to them, second is their position relative to us
    case classify(other)
    when :neg_neg
      return self
    when :neg_pos
      return self
    when :pos_neg
      return @negative.recursive_partition_for_negative(other)
    when :pos_pos
      return @positive.recursive_partition_for_negative(other)
    when :both
      return self
    when :on_parallel
      return @negative.recursive_partition_for_negative(other)
    when :on_antiparallel
      return @positive.recursive_partition_for_negative(other)
    end
  end

  def recursive_partition_for_positive(other)
    return self unless @position
    case classify(other)
    when :neg_neg
      return @negative.recursive_partition_for_positive(other)
    when :neg_pos
      return @positive.recursive_partition_for_positive(other)
    when :pos_neg
      return self
    when :pos_pos
      return self
    when :both
      return self
    when :on_parallel
      return @positive.recursive_partition_for_positive(other)
    when :on_antiparallel # (Note that this is technically impossible with current formulation)
      return @negative.recursive_partition_for_positive(other)
    end
  end

  def split(position, label_positive, label_negative)
    result = @cell.partition(position, @all_cells)

    if result == :positive_non_partition
      [self, nil]
    elsif result == :negative_non_partition
      [nil, self]
    else
      @label = nil
      @position = position # Known issue - this is numerically unstable at origin
      
      parent_nodes = []
      current = self
      while current
        parent_nodes << [current.parent, current.parent_positive] if current.parent
        current = current.parent
      end
      
      @boundary = intersect_with_universe
      parent_nodes.reverse.each do |node|
        positive, negative = node.first.partition_polygon(@boundary)
        if node.last
          @boundary = positive
        else
          @boundary = negative
      end
      end

      @cell = nil
      @positive = Node.new(label_positive, self, true, @name + 'P', result[:positive], @all_cells)
      @negative = Node.new(label_negative, self, false, @name + 'N', result[:negative], @all_cells)
      [@positive, @negative]
    end
  end

  def union!(other_tree, subtract = false)
#    puts "Computing union for #{other_tree.name} into #{@name}"
    if @position
      # This is a branch node, so partition the other tree and recursively apply
      positive_other_tree, negative_other_tree = other_tree.partition(self)
#      puts "Propagating: #{positive_other_tree}, #{negative_other_tree}"
      @positive.union!(positive_other_tree, subtract)
      @negative.union!(negative_other_tree, subtract)
    else
#      puts "Copying #{other_tree.name} into #{@name}:"
      other_tree.recursively_copy_into(self, subtract)
    end
  end

  def subtract!(other_tree)
#    puts "in subtract"
    union!(other_tree, true)
  end

  private

  def classify(other)
    their_relations = other.boundary.map{|p| on_positive_side?(p)}
    our_relations = boundary.map{|p| other.on_positive_side?(p)}

    if their_relations.all?{|o| o.nil?} # All on boundary
      return :on_parallel # Note that this is because current representation doesn't permit anti-parallel arrangement
    else
      if their_relations.all?{|o| o != false} # All positive or on boundary
        if our_relations.all?{|o| o != false}
          return :pos_pos
        else
          return :neg_pos
        end
      elsif their_relations.all?{|o| o != true} # All negative or on boundary
        if our_relations.all?{|o| o != false}
          return :pos_neg
        else
          return :neg_neg
        end
      else
        return :both
      end
    end
  end
end
