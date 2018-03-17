module logic.demo.RandomPoint;

import std.random;
import d2d;
import logic.demo.PointGetter;

/**
 * Randomly chooses points between the y scale
 */
class RandomPoint : PointGetter {

    dVector scale; ///The interval from which points are picked
 
    this(dVector scale, double dt, double startTime) {
        this.scale = scale;
        this.dt = dt;
        this.time = startTime;
    }

    override double getPoint() {
        this.time += this.dt;
        double point = uniform(this.scale.x, this.scale.y);
        this.points.add(this.time, point);
        return point;
    }

}