require 'spec_helper'

describe BoundaryRep do
  context 'for the universe' do
    it 'should calculate the right boundary rep' do
      root = Node.new(false)

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
end
