class Cuboid
  attr_reader :polygons

  def initialize(size_x, size_y, size_z)
    vertices = {
      'mmm' => [-size_x/2.0, -size_y/2.0, -size_z/2.0],
      'mmp' => [-size_x/2.0, -size_y/2.0, size_z/2.0],
      'mpm' => [-size_x/2.0, size_y/2.0, -size_z/2.0],
      'mpp' => [-size_x/2.0, size_y/2.0, size_z/2.0],
      'pmm' => [size_x/2.0, -size_y/2.0, -size_z/2.0],
      'pmp' => [size_x/2.0, -size_y/2.0, size_z/2.0],
      'ppm' => [size_x/2.0, size_y/2.0, -size_z/2.0],
      'ppp' => [size_x/2.0, size_y/2.0, size_z/2.0]
    }
    @polygons = []
    @polygons += side(vertices['mmm'], vertices['mpm'], vertices['mpp'], vertices['mmp'])
    @polygons += side(vertices['pmm'], vertices['pmp'], vertices['ppp'], vertices['ppm'])
    @polygons += side(vertices['mmm'], vertices['mmp'], vertices['pmp'], vertices['pmm'])
    @polygons += side(vertices['mpm'], vertices['ppm'], vertices['ppp'], vertices['mpp'])
    @polygons += side(vertices['mmm'], vertices['pmm'], vertices['ppm'], vertices['mpm'])
    @polygons += side(vertices['mmp'], vertices['mpp'], vertices['ppp'], vertices['pmp'])
  end

  def translate!(x, y, z)
    @polygons.map! do |p|
      p.map do |v|
        [v[0] + x, v[1] + y, v[2] + z]
      end
    end
    self
  end

  private

  def side(v1, v2, v3, v4)
    [
      [v1, v2, v4],
      [v2, v3, v4]
    ]
  end
end
