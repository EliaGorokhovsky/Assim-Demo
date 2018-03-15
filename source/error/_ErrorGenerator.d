module error.ErrorGenerator;

import data.Timeseries;
import data.Vector;

/**
 * A class that deals with generation of noise from a particular point
 */
abstract class ErrorGenerator {

    Timeseries!Vector truth;

    Vector opCall(double time) {
        return this.generate(time);
    }

    Vector generate(double time);

}