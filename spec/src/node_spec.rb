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

  describe 'merging trees' do
    context 'for simple, orthogonal trees' do
      it 'should correctly merge' do
        root1 = Node.new(false)
        root1.split([1.0, 0.0, 0.0], false, true)
        root2 = Node.new(false)
        root2.split([0.0, 1.0, 0.0], false, true)
        root1.union!(root2)
        root1.leaf_count.should == 4
        root1.interior_leaf_count.should == 3
      end
    end

    context 'for trees with parallel boundaries' do
      it 'should correctly merge' do
        root1 = Node.new(false)
        root1.split([1.0, 0.0, 0.0], false, false)
        root2 = Node.new(false)
        root2.split([2.0, 0.0, 0.0], false, false)
        root1.union!(root2)
        root1.leaf_count.should == 3
      end

      it 'should implement re-partitioning of boundaries during merge' do
        raise 'Not yet implemented'
      end
    end

    context 'for trees which don\'t fully overlap' do
      it 'should correctly merge' do
        root1 = Node.new(false)
        positive, negative = root1.split([1.0, 0.0, 0.0], false, false)
        negative.split([0.0, 1.0, 0.0], false, false)
        root2 = Node.new(false)
        root2.split([2.0, 0.0, 0.0], false, false)
        root1.union!(root2)
        root1.leaf_count.should == 4
      end
    end
  end
end
