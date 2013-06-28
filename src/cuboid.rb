#require './node'

class Cuboid
  attr_reader :root

  def initialize(position, size_x, size_y, size_z)
    @root = Node.new(true)
    positive, negative = @root.split([position[0] + size_x/2.0, 0.0, 0.0], false, true)
    positive, negative = negative.split([position[0] - size_x/2.0, 0.0, 0.0], false, true)
    positive, negative = negative.split([0.0, position[1] + size_y/2.0, 0.0], false, true)
    positive, negative = negative.split([0.0, position[1] - size_y/2.0, 0.0], false, true)
    positive, negative = negative.split([0.0, 0.0, position[2] + size_z/2.0], false, true)
    positive, negative = negative.split([0.0, 0.0, position[2] - size_z/2.0], false, true)
  end

  def union!(other_root)
    raise 'Not Implemented'
  end
end
