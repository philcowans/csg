require './cuboid'

class Corner
  def initialize
    @params = {
      :material_thickness => 3.0,
      :side_thickness => 2.0,
      :base_overhang => 1.0,
      :base_size => 30.0,
      :side_height => 30.0
    }
    @parts = {}

    base_translation_xy = @params[:base_size] / 2.0 - (@params[:side_thickness] + @params[:base_overhang] + @params[:material_thickness] / 2.0)
    side_translation_z = @params[:side_height] / 2.0

    @parts[:base] = Cuboid.new(@params[:base_size], @params[:base_size], @params[:material_thickness] + 2 * @params[:side_thickness]).
      translate!(base_translation_xy, base_translation_xy, 0.0)
    @parts[:front] = Cuboid.new(@params[:base_size], @params[:material_thickness] + @params[:base_overhang] + 2 * @params[:side_thickness], @params[:side_height] + @params[:material_thickness] + 2 * @params[:side_thickness]).
      translate!(base_translation_xy, -(@params[:base_overhang] / 2.0), side_translation_z)
    @parts[:side] = Cuboid.new(@params[:material_thickness] + @params[:base_overhang] + 2 * @params[:side_thickness], @params[:base_size], @params[:side_height] + @params[:material_thickness] + 2 * @params[:side_thickness]).
      translate!((@params[:base_overhang] / 2.0), base_translation_xy, side_translation_z)
  end

  def polygons
    @parts[:base].polygons + @parts[:front].polygons + @parts[:side].polygons
  end
end
