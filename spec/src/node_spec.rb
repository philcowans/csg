require 'spec_helper'

describe Node do
  describe 'calculating boundary representations' do
    context 'for a single division of space' do
      it 'should correctly calculate the vertices of the boundary' do
        root = Node.new(false)
        root.split([1.0, 0.0, 0.0], false, false)
        boundary = root.boundary
        i = boundary.index([1.0, 10000.0, 10000.0])
        boundary.rotate(i).zip([
          [1.0, 10000.0, 10000.0],
          [1.0, -10000.0, 10000.0],
          [1.0, -10000.0, -10000.0],
          [1.0, 10000.0, -10000.0]
        ]) do |o|
          o.first.zip(o.last) do |i|
            (i.first - i.last).abs.should be < 0.001
          end
        end
      end
    end

    context 'for two divisions of space' do
      it 'should correctly calculate the vertices of the boundary' do
        root = Node.new(false)
        positive, negative = root.split([1.0, 0.0, 0.0], false, false)
        positive.split([0.0, 1.0, 0.0], false, false)
        boundary = positive.boundary
        i = boundary.index([1.0, 1.0, 10000.0])
        boundary.rotate(i).zip([
          [1.0, 1.0, 10000.0],
          [10000.0, 1.0, 10000.0],
          [10000.0, 1.0, -10000.0],
          [1.0, 1.0, -10000.0]
        ]) do |o|
          o.first.zip(o.last) do |i|
            (i.first - i.last).abs.should be < 0.001
          end
        end
      end
    end
  end
end
