module logic.error.ErrorGenerator;

import logic.data.Timeseries;
import logic.data.Vector;

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