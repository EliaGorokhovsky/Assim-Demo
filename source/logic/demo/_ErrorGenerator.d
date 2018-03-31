module logic.demo.ErrorGenerator;

import logic.data.Timeseries;
import logic.data.Vector;

/**
 * Generates an observation by permuting a value
 */
abstract class ErrorGenerator {

    Timeseries!double points;

    Vector observe(Vector base, double time);

}