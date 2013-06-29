# Constructive Solid Geometry

An experimental library to support constructive solid geometry (CSG)
in Ruby. CSG is an approach to constructing solid objects through set
operations, e.g. describing an object as the intersection of a cube
and a sphere. More information on
[Wikipedia](http://en.wikipedia.org/wiki/Constructive_solid_geometry).

There are a few reasons why I want to do this:

* I'm generallyinterested in learning about how to do this kind of
  thing.
* I want to do 3D modelling, but I don't really want to learn a
  proprietory CAD interface if I can help it.
* I'm interested in ways of creating parameterised models, e.g. to
  introduce flexibility w.r.t. material thickness.
* I'm interested in code as a way to better represent the conceptual
  structure of a model, facilitate collaborative working, document the
  change logs via git, etc.
* It might be fun to generate models programatically.

A couple of papers this is based on:

* Merging BSP Trees Yields Polyhedral Set Operations, Naylor et. al.,
  Computer Graphics, vol. 24, no. 1, August 1990.
* Efficient Boundary Extraction of BSP Solids Based on Clipping
  Operations, Wand and Manocha, IEEE Transations on Visualization and
  Computer Graphics.
