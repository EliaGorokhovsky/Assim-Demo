module logic.demo.PointGetter;

import logic.data.Timeseries;

/**
 * Controls getting point values to display.
 */
abstract class PointGetter {

    Timeseries!double points; ///The list of points that are created by this object
    double dt;
    double time; ///The time at which a measurement should be taken
    double startTime;
    double initialPosition;

    double getPoint(); ///All child classes must be able to return a point value

}