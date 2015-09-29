# Smouz

Author: Charles Parnot

Contact: charles.parnot@gmail.com


### Description

Smouz is an example of function smoothing with bound constraints. The derivative at each point is based on the average of the slopes of the segment before and after the point. It is drawn using Bezier paths by placing the control points on the corresponding tangent, spacing the points evenly on the x axis (assuming “tightness” _t_ is set to 3.0 (otherwise at a fraction 1/_t_ of the delta x before and after the point). The output will have a continuous second derivative when a “tightness” of 3.0 is used, except when adjustments are needed to stay within the bounds.

The paths are created in ~20 lines of code with a simple loop over the initial points. Half of the code deals with the (optional) enforcing of bounds. It expects the bounds to be a rectangle of 100.0 x 100.0, but that can be easily changed.

<img src="smouz-screenshot.png" height="320px" alt="Smouz Screenshot">


### License

The entire code is released under the modified BSD License. Please read the text of the license included with the project for more details.



### Changelog

Sometime in 2004?

* Initial code

Sometime in 2014

* Modernized
* Some tweaks

Sept 2015

* Updated to Xcode 6
* Git
* Released under BSD license


### Todo

* Rewrite in Swift before 2024
