require './cuboid'
require './node'

class Corner
  attr_reader :parts

  def initialize
    @params = {
      :material_thickness => 3.0,
      :side_thickness => 2.0,
      :base_overhang => 1.0,
      :base_size => 30.0,
      :side_height => 30.0
    }

    base_translation_xy = @params[:base_size] / 2.0 - (@params[:side_thickness] +
      @params[:base_overhang] + @params[:material_thickness] / 2.0)

    side_translation_z = @params[:side_height] / 2.0

    @parts = {
      :base => Cuboid.new([base_translation_xy, base_translation_xy, 0.0],
                      @params[:base_size],
                      @params[:base_size],
                      @params[:material_thickness] + 2 * @params[:side_thickness]),
      :front => Cuboid.new([base_translation_xy, -(@params[:base_overhang] / 2.0), side_translation_z],
                       @params[:base_size],
                       @params[:material_thickness] + @params[:base_overhang] + 2 * @params[:side_thickness],
                       @params[:side_height] + @params[:material_thickness] + 2 * @params[:side_thickness]),
      :side => Cuboid.new([-(@params[:base_overhang] / 2.0), base_translation_xy, side_translation_z],
                      @params[:material_thickness] + @params[:base_overhang] + 2 * @params[:side_thickness],
                      @params[:base_size],
                      @params[:side_height] + @params[:material_thickness] + 2 * @params[:side_thickness]),
      :panel_front => Cuboid.new([@params[:material_thickness]/2.0 + @params[:side_thickness] + @params[:base_size], 0.0, side_translation_z - 1.0],
                             @params[:base_size] * 3.0,
                             @params[:material_thickness],
                             @params[:side_height])
    }
  end

  def root
    root = Node.new(false)
    root.union!(@parts[:front].root)
    root.union!(@parts[:side].root)
    root.union!(@parts[:base].root)
    root.subtract!(@parts[:panel_front].root)
    root
  end
end
