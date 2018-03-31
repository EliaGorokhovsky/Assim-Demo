module logic.demo.GaussianObserver;

import mir.random;
import mir.random.variable;
import logic.data.Timeseries;
import logic.data.Vector;
import logic.demo.ErrorGenerator;

/**
 * Generates observation through Gaussian permutation from a point
 */
class GaussianObserver : ErrorGenerator {

    Vector error;

    this(double xError, double yError, double zError) {
        this.error = Vector(xError, yError, zError);
        this.points = new Timeseries!double([], []);
    }

    override Vector observe(Vector base, double time) {
        auto gen = Random(unpredictableSeed);
        auto normalX = NormalVariable!double(base.x, this.error.x);
        auto normalY = NormalVariable!double(base.y, this.error.y);
        auto normalZ = NormalVariable!double(base.z, this.error.z);
        Vector obs = Vector(normalX(gen), normalY(gen), normalZ(gen));
        this.points.add(time, obs.x);
        return obs;
    }

}