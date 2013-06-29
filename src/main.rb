require 'rubygems'
require './boundary_rep'
require './corner'
require 'rvg/rvg'

c = Corner.new
root = c.root

boundary_rep = BoundaryRep.new(10000.0)
boundary_rep.partition_by_bsp_tree!(root)
polygons = boundary_rep.polygons

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
