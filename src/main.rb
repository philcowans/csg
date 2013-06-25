require 'rubygems'
require './corner'
require 'rvg/rvg'

c = Corner.new

include Magick
RVG::dpi = 72

rvg = RVG.new(2.5.in, 2.5.in).viewbox(0,0,250,250) do |canvas|
  canvas.background_fill = 'white'
  canvas.styles(:stroke => 'black')
  c.polygons.each do |p|
    puts p.inspect
    canvas.polyline(p[0][0], p[0][1], p[1][0], p[1][1], p[2][0], p[2][1])
  end
end

rvg.draw.write('output.gif')
