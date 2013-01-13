class Dimension
  attr_reader :metric, :type

  def initialize(type, metric)
    @type = type
    @metric = metric
  end
end

class Region
end

class Rectangle < Region
  def initialize(width, height)
    @width = width
    @height = height
  end
end

class HorizontalGroup < Region
  def initialize(components)
    @components = components
  end
end

class VerticalGroup < Region
  def initialize(compontents)
    @components = components
  end
end

model_params = {
  :cavity_width => 62.0,
  :cavity_depth => 34.0,
  :cavity_height => 92.0,
  :material_width => 3.0,
  :tab_extension => 5.0
}

backpiece = Rectangle.new(Dimension.new(:fixed, model_params[:cavity_width]), Dimension.new(:fixed, model_params[:cavity_height]))
back_tab_left = Rectangle.new(Dimension.new(:fixed, model_params[:material_width] + model_params[:tab_extension]), Dimension.new(:relative, 1))
back_tab_right = Rectangle.new(Dimension.new(:fixed, model_params[:material_width] + model_params[:tab_extension]), Dimension.new(:relative, 1))
back_tab_bottom = Rectangle.new(Dimension.new(:relative, 1), Dimension.new(:fixed, model_params[:material_width] + model_params[:tab_extension]))

back = VerticalGroup.new([HorizontalGroup.new([back_tab_left, backpiece, back_tab_right]), back_tab_bottom])

