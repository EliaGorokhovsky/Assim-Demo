module logic.demo.PointGetter;

import logic.data.Timeseries;
import logic.data.Vector;
import logic.integrators.Integrator;
import logic.integrators.RK4;

/**
 * Controls getting point values to display.
 */
abstract class PointGetter {

    Timeseries!double points; ///The list of points that are created by this object
    double dt;
    double time; ///The time at which a measurement should be taken
    double startTime;
    double initialPosition;
    Vector position;
    Integrator integrator; ///Only useful in differential systems but needed for ensembles

    double getPoint(); ///All child classes must be able to return a point value

}