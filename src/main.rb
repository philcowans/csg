require 'rubygems'
require './boundary_rep'
require './corner'
require 'rvg/rvg'

c = Corner.new
# boundary_rep = BoundaryRep.new(10000.0)
# boundary_rep.partition_by_bsp_tree!(c.parts[:front].root)
# polygons = boundary_rep.polygons

# boundary_rep = BoundaryRep.new(10000.0)
# boundary_rep.partition_by_bsp_tree!(c.parts[:side].root)
# polygons += boundary_rep.polygons

# boundary_rep = BoundaryRep.new(10000.0)
# boundary_rep.partition_by_bsp_tree!(c.parts[:base].root)
# polygons += boundary_rep.polygons

root = c.root

boundary_rep = BoundaryRep.new(10000.0)
boundary_rep.partition_by_bsp_tree!(root)
polygons = boundary_rep.polygons


# puts root.interior_leaf_count

name = "test"

puts "solid #{name}"

def cross(a,b)
  [
    a[1]*b[2] - a[2]*b[1],
    a[2]*b[0] - a[0]*b[2],
    a[0]*b[1] - a[1]*b[0]
  ]
end

def dot(a,b)
  a[0]*b[0] + a[1]*b[1] + a[2]*b[2]
end

polygons.each do |polygon|
  a = polygon[0]
  b = polygon[1]
  c = polygon[2]
  v1 = [b[0]-a[0], b[1]-a[1], b[2]-a[2]]
  v2 = [a[0]-c[0], a[1]-c[1], a[2]-c[2]]
  normal = cross(v1, v2)
  n = Math.sqrt(dot(normal, normal))
  puts "facet normal #{normal.map{|c| '%e' % (c/n)}.join(' ')}"
  puts "    outer loop"
  polygon.each do |vertex|
    puts "        vertex #{vertex.map{|c| '%e' % c}.join(' ')}"
  end
  puts "    endloop"
  puts "endfacet"
end

puts "endsolid #{name}"

#puts c.root.inspect

# include Magick
# RVG::dpi = 72

# rvg = RVG.new(2.5.in, 2.5.in).viewbox(0,0,250,250) do |canvas|
#   canvas.background_fill = 'white'
#   canvas.styles(:stroke => 'black')
#   c.polygons.each do |p|
#     puts p.inspect
#     canvas.polyline(p[0][0], p[0][1], p[1][0], p[1][1], p[2][0], p[2][1])
#   end
# end

# rvg.draw.write('output.gif')
