class Node
  attr_accessor :label
  attr_reader :boundary, :negative, :parent, :parent_positive, :position, :positive

  UNIVERSE_SIZE = 10000.0

  def initialize(label, parent = nil, parent_positive = nil)
    @label = label
    @positive = nil
    @negative = nil
    @position = nil
    @boundary = nil
    @parent = parent
    @parent_positive = parent_positive
  end

  def boundary_representation
    v_ppp = [UNIVERSE_SIZE, UNIVERSE_SIZE, UNIVERSE_SIZE]
    v_ppm = [UNIVERSE_SIZE, UNIVERSE_SIZE, -UNIVERSE_SIZE]
    v_pmp = [UNIVERSE_SIZE, -UNIVERSE_SIZE, UNIVERSE_SIZE]
    v_pmm = [UNIVERSE_SIZE, -UNIVERSE_SIZE, -UNIVERSE_SIZE]
    v_mpp = [-UNIVERSE_SIZE, UNIVERSE_SIZE, UNIVERSE_SIZE]
    v_mpm = [-UNIVERSE_SIZE, UNIVERSE_SIZE, -UNIVERSE_SIZE]
    v_mmp = [-UNIVERSE_SIZE, -UNIVERSE_SIZE, UNIVERSE_SIZE]
    v_mmm = [-UNIVERSE_SIZE, -UNIVERSE_SIZE, -UNIVERSE_SIZE]

    e_xpp = [v_ppp, v_mpp]
    e_xpm = [v_ppm, v_mpm]
    e_xmp = [v_pmp, v_ppm]
    e_xmm = [v_pmm, v_mmm]
    e_pxp = [v_ppp, v_pmp]
    e_pxm = [v_ppm, v_pmm]
    e_mxp = [v_mpp, v_mmp]
    e_mxm = [v_mpm, v_mmm]
    e_ppx = [v_ppp, v_ppm]
    e_pmx = [v_pmp, v_pmm]
    e_mpx = [v_mpp, v_mpm]
    e_mmx = [v_mmp, v_mmm]

    f_xp = [e_pxp, e_pxm, e_ppx, e_pmx]
    f_xm = [e_mxp, e_mxm, e_mpx, e_mmx]
    f_yp = [e_xpp, e_xpm, e_ppx, e_mpx]
    f_ym = [e_xmp, e_xmm, e_pmx, e_mmx]
    f_zp = [e_xpp, e_xmp, e_pxp, e_mxp]
    f_zm = [e_xpm, e_xmm, e_pxm, e_mxm]

    cells = [[f_xp, f_xm, f_yp, f_ym, f_zp, f_zm]]

    recursive_partition_cells(cells, 0)
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
    if d > position_length
      true
    elsif d < position_length
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

  def partition_cell(cell)
    vertices = []
    cell.each do |f|
      f.each do |e|
        vertices += e
      end
    end
    labeled_vertices = {}
    vertices.uniq.each{|v| labeled_vertices[v] = on_positive_side?(v)}
    spanning_edges = []
    cell.each do |f|
      f.each do |e|
        if ((e[0] == true) && (e[1] == false)) || ((e[1] == true) && (e[0] == false))
          f = (dot(@position, @position) - dot(e[0], @position)) /
            (dot(e[1], @position) - dot(e[0], @position))
          intersect = [
            (1-f) * e[0][0] + f * e[1][0],
            (1-f) * e[0][1] + f * e[1][1],
            (1-f) * e[0][2] + f * e[1][2]
          ]
          # Create new vertex at intersect
          # Add new edges
          # Update appropriate faces
          # Delete old edge
        end
      end
    end
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
        if next_vertex.last != v.last
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

  def recursively_copy_into(other_node)
    if @position.nil?
      other_node.label = other_node.label || @label
    else
      positive, negative = other_node.split(@position, other_node.label, other_node.label)
      @positive.recursively_copy_into(positive)
      @negative.recursively_copy_into(negative)
    end
  end

  def recursive_partition_cells(cells, i)
    if @boundary
      positive, negative = partition_cell(cells[i])
      cells[i] = nil # Todo - need better data structures here
      cells << positive
      cells << negative
      initial_size = cells.size # This could in theory change during subsequent operations, so need to keep stable
      @positive.recursive_partition_cells(cells, initial_size - 2)
      @negative.recursive_partition_cells(cells, initial_size - 1)
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

    @positive = Node.new(label_positive, self, true)
    @negative = Node.new(label_negative, self, false)
    [@positive, @negative]
  end

  def union!(other_tree)
    if @position
      # This is a branch node, so partition the other tree and recursively apply
      positive_other_tree, negative_other_tree = other_tree.partition(self)
      @positive.union!(positive_other_tree)
      @negative.union!(negative_other_tree)
    else
      other_tree.recursively_copy_into(self)
    end
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
