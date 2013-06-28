require 'spec_helper'

require 'cuboid'

describe BoundaryRep do
  context 'for the universe' do
    it 'should calculate the right boundary rep' do
      root = Node.new(true)

      boundary_rep = BoundaryRep.new(10000.0)
      boundary_rep.partition_by_bsp_tree!(root)

      boundary_rep.polygons.size.should == 12

      boundary_rep.polygons.map{|p| p.map{|v| v[0]}}.flatten.uniq.sort.should == [-10000.0, 10000.0]
      boundary_rep.polygons.map{|p| p.map{|v| v[1]}}.flatten.uniq.sort.should == [-10000.0, 10000.0]
      boundary_rep.polygons.map{|p| p.map{|v| v[2]}}.flatten.uniq.sort.should == [-10000.0, 10000.0]
    end
  end

  context 'for a simple division of space' do
    it 'should calculate the right boundary rep' do
      root = Node.new(false)
      root.split([1.0, 0.0, 0.0], true, false)

      boundary_rep = BoundaryRep.new(10000.0)
      boundary_rep.partition_by_bsp_tree!(root)

      boundary_rep.polygons.size.should == 12

      boundary_rep.polygons.map{|p| p.map{|v| v[0]}}.flatten.uniq.sort.should == [1.0, 10000.0]
      boundary_rep.polygons.map{|p| p.map{|v| v[1]}}.flatten.uniq.sort.should == [-10000.0, 10000.0]
      boundary_rep.polygons.map{|p| p.map{|v| v[2]}}.flatten.uniq.sort.should == [-10000.0, 10000.0]
    end
  end

  context 'for a cube' do
    it 'should calculate the right boundary rep' do
      root = Node.new(false)
      _, negative = root.split([-4.0, 0.0, 0.0], false, true)
      _, negative = negative.split([6.0, 0.0, 0.0], false, true)
      _, negative = negative.split([0.0, -5.0, 0.0], false, true)
      _, negative = negative.split([0.0, 5.0, 0.0], false, true)
      _, negative = negative.split([0.0, 0.0, -5.0], false, true)
      negative.split([0.0, 0.0, 5.0], false, true)

      boundary_rep = BoundaryRep.new(10000.0)
      boundary_rep.partition_by_bsp_tree!(root)

      boundary_rep.polygons.size.should == 12

      puts boundary_rep.polygons.inspect

      boundary_rep.polygons.map{|p| p.map{|v| v[0]}}.flatten.uniq.sort.zip([-4.0, 6.0]).each do |c|
        (c.first - c.last).should be < 0.001
      end
      boundary_rep.polygons.map{|p| p.map{|v| v[1]}}.flatten.uniq.sort.zip([-5.0, 5.0]).each do |c|
        (c.first - c.last).should be < 0.001
      end
      boundary_rep.polygons.map{|p| p.map{|v| v[2]}}.flatten.uniq.sort.zip([-5.0, 5.0]).each do |c|
        (c.first - c.last).should be < 0.001
      end
    end
  end
end
